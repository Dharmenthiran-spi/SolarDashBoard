import '../Models/report.dart';
import '../Services/report_service.dart';
import '../Services/export_service.dart';
import '../Services/machine_service.dart';
import '../Models/machine.dart';
import 'global_state.dart';
import 'package:flutter/material.dart';

class ReportViewModel extends ChangeNotifier {
  final GlobalState globalState = GlobalState();

  // Filter Controllers
  final TextEditingController machineController = TextEditingController();
  
  // Filter state
  int? selectedMachineId;
  DateTime? fromDate;
  DateTime? toDate;

  // Manual Entry Controllers
  final TextEditingController energyController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController waterController = TextEditingController();
  DateTime? manualStartTime;
  DateTime? manualEndTime;

  // Dropdown data - fetched directly from services
  List<Machine> dropdownMachines = [];

  List<Report> _allReports = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Report> get reports => _allReports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchReports() async {
    _setLoading(true);
    try {
      final customerId = globalState.filterCustomerId;
      final response = await ReportService.getAll(
        machineId: selectedMachineId,
        customerId: customerId,
        fromTime: fromDate,
        toTime: toDate,
      );
      if (response['success']) {
        final data = response['data'];
        _allReports = (data as List)
            .map((item) => Report.fromJson(item))
            .toList();
        _errorMessage = null;
        await _fetchDropdownMachines(); // Fetch dropdown data for machines
      } else {
        _errorMessage = response['error'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void setDateRange(DateTime? start, DateTime? end) {
    fromDate = start;
    toDate = end;
    notifyListeners();
  }

  void clearFilters() {
    selectedMachineId = null;
    fromDate = null;
    toDate = null;
    machineController.clear();
    fetchReports();
    notifyListeners();
  }

  Future<bool> exportToExcel() async {
    if (_allReports.isEmpty) return false;
    return await ExportService.exportToExcel(_allReports, 'Report_Log_${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<bool> exportToPDF() async {
    if (_allReports.isEmpty) return false;
    return await ExportService.exportToPDF(_allReports, 'Report_Log_${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<bool> printReports() async {
    if (_allReports.isEmpty) return false;
    return await ExportService.printReports(_allReports);
  }

  String calculateDuration(DateTime start, DateTime end) {
    final diff = end.difference(start);
    if (diff.isNegative) return "0s";

    int days = diff.inDays;
    int hours = diff.inHours.remainder(24);
    int minutes = diff.inMinutes.remainder(60);
    int seconds = diff.inSeconds.remainder(60);

    List<String> parts = [];
    if (days > 0) parts.add("${days}d");
    if (hours > 0) parts.add("${hours}h");
    if (minutes > 0) parts.add("${minutes}m");
    if (seconds > 0) parts.add("${seconds}s");

    return parts.isEmpty ? "0s" : parts.join(" ");
  }

  Future<bool> saveManualReport(int machineId) async {
    if (manualStartTime == null || manualEndTime == null) return false;

    final machine = dropdownMachines.firstWhere(
      (m) => m.id == machineId,
      orElse: () => Machine(id: 0, name: '', serialNo: '', companyId: 0, customerId: 0),
    );
    if (machine.id == 0) return false;

    final duration = calculateDuration(manualStartTime!, manualEndTime!);

    final data = {
      "MachineID": machineId,
      "CompanyID": machine.companyId,
      "CustomerID": machine.customerId,
      "StartTime": manualStartTime!.toIso8601String(),
      "EndTime": manualEndTime!.toIso8601String(),
      "Duration": duration,
      "EnergyConsumption": "${energyController.text} kWh",
      "AreaCovered": "${areaController.text} m²",
      "WaterUsage": "${waterController.text} L",
    };

    _setLoading(true);
    try {
      final response = await ReportService.create(data);
      if (response['success']) {
        await fetchReports();
        clearManualControllers();
        return true;
      } else {
        _errorMessage = response['error'];
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearManualControllers() {
    energyController.clear();
    areaController.clear();
    waterController.clear();
    manualStartTime = null;
    manualEndTime = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Fetch dropdown data for machines
  Future<void> _fetchDropdownMachines() async {
    try {
      final customerId = globalState.filterCustomerId;
      final machineResponse = await MachineService.getAll(customerId: customerId);
      if (machineResponse['success']) {
        dropdownMachines = (machineResponse['data'] as List)
            .map((e) => Machine.fromJson(e))
            .toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching dropdown machines: $e');
    }
  }

  @override
  void dispose() {
    machineController.dispose();
    energyController.dispose();
    areaController.dispose();
    waterController.dispose();
    super.dispose();
  }
}
