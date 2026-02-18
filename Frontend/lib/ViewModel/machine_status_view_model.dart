import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../Models/machine_status.dart';
import '../Services/machine_status_service.dart';

class MachineStatusViewModel extends ChangeNotifier {
  final Map<int, MachineStatus> _liveStatuses = {};
  Timer? _pollingTimer;
  bool _isPolling = false;
  final Random _random = Random();

  Map<int, MachineStatus> get liveStatuses => _liveStatuses;

  void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      fetchAllLiveStatus();
    });
    // Initial fetch
    fetchAllLiveStatus();
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _isPolling = false;
  }

  Future<void> fetchAllLiveStatus() async {
    try {
      final response = await MachineStatusService.getAllLive();
      if (response['success']) {
        final List data = response['data'];
        bool hasChanges = false;
        
        for (var item in data) {
          final backendStatus = MachineStatus.fromJson(item);
          final prevStatus = _liveStatuses[backendStatus.machineId];
          
          // Decorate backend data with simulated telemetry
          final detailedStatus = _simulateDetailedTelemetry(backendStatus);
          
          // Check if anything meaningful changed (excluding timestamp)
          if (prevStatus == null || !_isStatusEqual(prevStatus, detailedStatus)) {
            _liveStatuses[detailedStatus.machineId] = detailedStatus;
            hasChanges = true;
          }
        }
        
        if (hasChanges) {
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching live status: $e');
    }
  }

  bool _isStatusEqual(MachineStatus a, MachineStatus b) {
    // Compare essential telemetry fields to decide if we should refresh
    return a.status == b.status &&
           a.energyValue == b.energyValue &&
           a.waterValue == b.waterValue &&
           a.areaValue == b.areaValue &&
           a.batteryLevel == b.batteryLevel &&
           a.waterLevel == b.waterLevel &&
           a.brushRPM == b.brushRPM &&
           a.brushTemp == b.brushTemp &&
           a.speed == b.speed &&
           a.obstacleDetected == b.obstacleDetected &&
           a.emergencyStop == b.emergencyStop;
  }

  /// Injects simulated data for fields not yet available in backend
  MachineStatus _simulateDetailedTelemetry(MachineStatus base) {
    // Maintain some stability if we already have a status for this machine
    final prev = _liveStatuses[base.machineId];
    
    // 80% chance to keep the same simulation values to avoid "flickering"
    final shouldChange = prev == null || _random.nextDouble() > 0.8;
    
    if (!shouldChange) {
      return MachineStatus(
        statusId: base.statusId,
        machineId: base.machineId,
        status: base.status,
        energyValue: base.energyValue,
        waterValue: base.waterValue,
        areaValue: base.areaValue,
        timestamp: base.timestamp,
        // Carry over previous simulation values
        mode: prev.mode,
        timer: (prev.timer) + 5, // Keep timer running
        batteryLevel: prev.batteryLevel,
        batteryVoltage: prev.batteryVoltage,
        isCharging: prev.isCharging,
        waterLevel: prev.waterLevel,
        pumpStatus: prev.pumpStatus,
        brushRPM: prev.brushRPM,
        brushTemp: prev.brushTemp,
        isBrushJam: prev.isBrushJam,
        speed: prev.speed,
        direction: prev.direction,
        emergencyStop: prev.emergencyStop,
        obstacleDetected: prev.obstacleDetected,
        areaToday: base.areaValue,
        cleaningTime: (prev.cleaningTime) + 5,
        totalCycles: prev.totalCycles,
      );
    }

    return MachineStatus(
      statusId: base.statusId,
      machineId: base.machineId,
      status: base.status,
      energyValue: base.energyValue,
      waterValue: base.waterValue,
      areaValue: base.areaValue,
      timestamp: base.timestamp,
      // Simulated fields
      mode: _random.nextDouble() > 0.9 ? 'Manual' : (prev?.mode ?? 'Auto'),
      timer: (prev?.timer ?? 0) + 5,
      batteryLevel: (prev?.batteryLevel ?? (85.0 + _random.nextDouble() * 15.0)) - (_random.nextDouble() * 0.1),
      batteryVoltage: 24.0 + (_random.nextDouble() * 0.4 - 0.2),
      isCharging: false,
      waterLevel: (prev?.waterLevel ?? (70.0 + _random.nextDouble() * 30.0)) - (_random.nextDouble() * 0.05),
      pumpStatus: _random.nextDouble() > 0.5,
      brushRPM: 2500 + _random.nextInt(500),
      brushTemp: 35.0 + _random.nextDouble() * 15.0,
      isBrushJam: _random.nextDouble() > 0.99,
      speed: 0.5 + _random.nextDouble() * 1.5,
      direction: (prev?.direction ?? 0) + (_random.nextDouble() * 10 - 5),
      emergencyStop: false,
      obstacleDetected: _random.nextDouble() > 0.97,
      areaToday: base.areaValue,
      cleaningTime: (prev?.cleaningTime ?? 0) + 5,
      totalCycles: prev?.totalCycles ?? _random.nextInt(100),
    );
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
