import 'package:flutter/material.dart';
import '../Models/dashboard_data.dart';
import '../Models/report.dart';
import '../Models/machine.dart';
import '../Services/dashboard_service.dart';
import '../Services/report_service.dart';
import '../Services/machine_service.dart';
import 'global_state.dart';

class DashboardViewModel extends ChangeNotifier {
  DashboardSummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;

  DashboardSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Machine? _selectedMachine;
  Machine? get selectedMachine => _selectedMachine;

  List<Report> _machineReports = [];
  List<Report> get machineReports => _machineReports;

  List<Machine> _allMachines = [];
  List<Machine> get allMachines => _allMachines;

  // Chart Duration State
  int _energyDuration = 7;
  int get energyDuration => _energyDuration;

  int _waterDuration = 7;
  int get waterDuration => _waterDuration;

  void toggleEnergyDuration(int days) {
    _energyDuration = days;
    notifyListeners();
  }

  void toggleWaterDuration(int days) {
    _waterDuration = days;
    notifyListeners();
  }

  List<DailyGraphicData> get energyData {
    if (_summary == null) return [];
    final data = _summary!.dailyEnergy;
    if (data.length <= _energyDuration) return data;
    return data.sublist(data.length - _energyDuration);
  }

  List<DailyGraphicData> get waterData {
    if (_summary == null) return [];
    final data = _summary!.dailyWater;
    if (data.length <= _waterDuration) return data;
    return data.sublist(data.length - _waterDuration);
  }

  Future<void> fetchSummary() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final customerId = GlobalState().filterCustomerId;
      final summaryResponse = await DashboardService.getSummary(
        customerId: customerId,
      );
      if (summaryResponse['success']) {
        _summary = DashboardSummary.fromJson(summaryResponse['data']);
      } else {
        _errorMessage = summaryResponse['error'];
      }

      final machineResponse = await MachineService.getAll();
      if (machineResponse['success']) {
        final allMachines = (machineResponse['data'] as List)
            .map((e) => Machine.fromJson(e))
            .toList();

        if (customerId != null) {
          _allMachines = allMachines
              .where((m) => m.customerId == customerId)
              .toList();
        } else {
          _allMachines = allMachines;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectMachine(Machine? machine) async {
    _selectedMachine = machine;
    _machineReports = [];
    notifyListeners();

    if (machine != null) {
      _isLoading = true;
      notifyListeners();
      try {
        final response =
            await ReportService.getAll(); // Ideally a filtered endpoint, but we can filter locally for now
        if (response['success']) {
          _machineReports = (response['data'] as List)
              .map((e) => Report.fromJson(e))
              .where((r) => r.machineId == machine.id)
              .toList();
        }
      } catch (e) {
        _errorMessage = e.toString();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
