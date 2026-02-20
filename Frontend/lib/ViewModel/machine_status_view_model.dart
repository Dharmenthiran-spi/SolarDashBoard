import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../Models/machine_status.dart';
import '../Services/machine_status_service.dart';
import '../Config/api_config.dart';

class MachineStatusViewModel extends ChangeNotifier {
  final Map<int, MachineStatus> _liveStatuses = {};
  final Map<int, WebSocketChannel> _channels = {};
  Timer? _pollingTimer;
  bool _isPolling = false;

  int? _activeCompanyId;
  int _reconnectDelay = 1; // Start with 1 second backoff
  bool _isConnecting = false;

  Map<int, MachineStatus> get liveStatuses => _liveStatuses;

  /// Starts polling only as a fallback when WebSockets are not healthy
  void startSmartPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      bool anyConnected = _channels.isNotEmpty;
      if (!anyConnected) {
        debugPrint(
          '🔔 WS disconnected. Falling back to polling... Attempting Reconnect.',
        );
        fetchAllLiveStatus();

        // Try to reconnect if we know the company ID
        if (_activeCompanyId != null) {
          connectToCompany(_activeCompanyId!);
        }
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  /// Connect to WebSocket for a specific machine for real-time updates
  void connectToMachine(int machineId) {
    if (_isConnecting) return;
    if (_channels.containsKey(machineId)) return;

    final wsUrl = "${ApiConfig.wsUrl}/realtime/$machineId".trim();
    try {
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channels[machineId] = channel;

      channel.stream.listen(
        (message) {
          _reconnectDelay = 1; 
          final data = json.decode(message);
          _handleRealtimeUpdate(machineId, data);
        },
        onError: (error) {
          debugPrint('WS Error for machine $machineId: $error');
          _disconnectFromMachine(machineId);
          _scheduleRecovery();
        },
        onDone: () {
          debugPrint('WS Closed for machine $machineId');
          _disconnectFromMachine(machineId);
          _scheduleRecovery();
        },
      );
    } catch (e) {
      debugPrint('WS Connection failed for machine $machineId: $e');
      _scheduleRecovery();
    }
  }

  /// Connect to WebSocket for an entire company for real-time fleet updates
  void connectToCompany(int companyId) {
    if (_isConnecting) return; // Guard against multiple simultaneous attempts
    _activeCompanyId = companyId; // Store for reconnection attempts

    _isConnecting = true;
    if (_channels.containsKey(-companyId)) {
      _isConnecting = false;
      return; // Use negative ID for company channels
    }

    // Aggressively sanitize URL: remove fragments (#) and trim
    final baseWsUrl = "${ApiConfig.wsUrl}/realtime/company/$companyId".trim();
    final sanitizedUri = Uri.parse(baseWsUrl).replace(fragment: '');
    final wsUrl = sanitizedUri.toString();
    
    try {
      debugPrint('🔌 Attempting WS Connection: $wsUrl');
      final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channels[-companyId] = channel;

      channel.stream.listen(
        (message) {
          _isConnecting = false;
          _reconnectDelay = 1; // Reset backoff on successful message
          final Map<String, dynamic> update = json.decode(message);
          
          if (update['type'] == 'heartbeat') return; // Ignore heartbeats

          final machineId = update['machine_id'];
          if (machineId != null) {
            _handleRealtimeUpdate(machineId, update);
          }
        },
        onError: (error) {
          _isConnecting = false;
          debugPrint('WS Error for company $companyId: $error');
          _disconnectFromCompany(companyId);
          _scheduleRecovery();
        },
        onDone: () {
          _isConnecting = false;
          debugPrint('WS Closed for company $companyId');
          _disconnectFromCompany(companyId);
          _scheduleRecovery();
        },
      );
    } catch (e) {
      _isConnecting = false;
      debugPrint('WS Connection failed for company $companyId: $e');
      _scheduleRecovery();
    }
  }

  void _scheduleRecovery() {
    // Implement Exponential Backoff (1s, 2s, 4s, 8s... max 30s)
    debugPrint('⏳ Recovering in $_reconnectDelay seconds...');
    Future.delayed(Duration(seconds: _reconnectDelay), () {
      if (_channels.isEmpty) {
          fetchAllLiveStatus();
          if (_activeCompanyId != null) connectToCompany(_activeCompanyId!);
      }
      // Double the delay for next time, up to 30s
      _reconnectDelay = (_reconnectDelay * 2).clamp(1, 30);
      startSmartPolling();
    });
  }

  void _disconnectFromCompany(int companyId) {
    _channels[-companyId]?.sink.close();
    _channels.remove(-companyId);
    // Don't clear _activeCompanyId here so we can reconnect later if needed
  }

  void _disconnectFromMachine(int machineId) {
    _channels[machineId]?.sink.close();
    _channels.remove(machineId);
  }

  void _handleRealtimeUpdate(int machineId, Map<String, dynamic> update) {
    final type = update['type'];
    final data = update['data'];

    final currentStatus =
        _liveStatuses[machineId] ??
        MachineStatus(
          statusId: 0,
          machineId: machineId,
          status: 'Online',
          energyValue: 0,
          waterValue: 0,
          areaValue: 0,
          timestamp: DateTime.now(),
        );

    late MachineStatus updatedStatus;

    if (type == 'telemetry') {
      // Merge telemetry data into existing status
      updatedStatus = MachineStatus(
        statusId: currentStatus.statusId,
        machineId: machineId,
        status: currentStatus.status,
        energyValue: currentStatus.energyValue,
        waterValue: currentStatus.waterValue,
        areaValue: currentStatus.areaValue,
        timestamp: DateTime.now(),
        // New values from telemetry
        batteryLevel: (data['battery'] ?? currentStatus.batteryLevel)
            .toDouble(),
        batteryVoltage: (data['solar_v'] ?? currentStatus.batteryVoltage)
            .toDouble(),
        waterLevel: (data['water'] ?? currentStatus.waterLevel).toDouble(),
        brushTemp: (data['extra']?['temp'] ?? currentStatus.brushTemp)
            .toDouble(),
        // Keep others
        mode: currentStatus.mode,
        timer: currentStatus.timer,
        isCharging: currentStatus.isCharging,
        pumpStatus: currentStatus.pumpStatus,
        brushRPM: currentStatus.brushRPM,
        isBrushJam: currentStatus.isBrushJam,
        speed: currentStatus.speed,
        direction: currentStatus.direction,
        emergencyStop: currentStatus.emergencyStop,
        obstacleDetected: currentStatus.obstacleDetected,
        areaToday: currentStatus.areaToday,
        cleaningTime: currentStatus.cleaningTime,
        totalCycles: currentStatus.totalCycles,
      );
    } else if (type == 'status') {
      // Merge status data
      updatedStatus = MachineStatus(
        statusId: currentStatus.statusId,
        machineId: machineId,
        status: data['status'] ?? currentStatus.status,
        energyValue: (data['energy'] ?? currentStatus.energyValue).toDouble(),
        waterValue: (data['water'] ?? currentStatus.waterValue).toDouble(),
        areaValue: (data['area'] ?? currentStatus.areaValue).toDouble(),
        timestamp: DateTime.now(),
        // Keep others
        mode: currentStatus.mode,
        timer: currentStatus.timer,
        batteryLevel: currentStatus.batteryLevel,
        batteryVoltage: currentStatus.batteryVoltage,
        isCharging: currentStatus.isCharging,
        waterLevel: currentStatus.waterLevel,
        pumpStatus: currentStatus.pumpStatus,
        brushRPM: currentStatus.brushRPM,
        brushTemp: currentStatus.brushTemp,
        isBrushJam: currentStatus.isBrushJam,
        speed: currentStatus.speed,
        direction: currentStatus.direction,
        emergencyStop: currentStatus.emergencyStop,
        obstacleDetected: currentStatus.obstacleDetected,
        areaToday: currentStatus.areaToday,
        cleaningTime: currentStatus.cleaningTime,
        totalCycles: currentStatus.totalCycles,
      );
    } else {
      return;
    }

    _liveStatuses[machineId] = updatedStatus;
    notifyListeners();
  }

  Future<void> fetchAllLiveStatus() async {
    try {
      final response = await MachineStatusService.getAllLive();
      if (response['success']) {
        final List data = response['data'];
        for (var item in data) {
          final backendStatus = MachineStatus.fromJson(item);
          _liveStatuses[backendStatus.machineId] = backendStatus;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching live status: $e');
    }
  }

  @override
  void dispose() {
    stopPolling();
    for (var channel in _channels.values) {
      channel.sink.close();
    }
    super.dispose();
  }
}
