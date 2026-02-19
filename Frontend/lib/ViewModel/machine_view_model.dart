import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // To pick images
import 'dart:convert'; // To encode image to base64
import 'dart:io'; // To read file
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List; // To check web
import '../Models/company.dart';
import '../Models/customer.dart';
import '../Models/machine.dart';
import '../Services/machine_service.dart';
import '../Services/company_service.dart';
import '../Services/customer_service.dart';
import 'global_state.dart';

class MachineViewModel extends ChangeNotifier {
  final GlobalState globalState = GlobalState();

  // TextEditingControllers for Add/Edit dialog
  final TextEditingController machineNameController = TextEditingController();
  final TextEditingController serialController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController companyController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController mqttUsernameController = TextEditingController();
  final TextEditingController mqttPasswordController = TextEditingController();

  // Dropdown state variables
  int? selectedCompanyId;
  int? selectedCustomerId;

  String? _selectedImageBase64;
  String? get selectedImageBase64 => _selectedImageBase64;
  String? _selectedImageName; // for UI display if needed

  List<Machine> _allMachines = [];
  List<Machine> _filteredMachines = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  final Set<int> _selectedIds = {};
  bool _isEditMode = false;
  final Map<int, Machine> _modifiedMachines = {};

  // Dropdown data - fetched directly from services
  List<Company> dropdownCompanies = [];
  List<Customer> dropdownCustomers = [];

  List<Machine> get machines =>
      _searchQuery.isEmpty ? _allMachines : _filteredMachines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEditMode => _isEditMode;
  Set<int> get selectedIds => _selectedIds;

  Future<void> fetchMachines() async {
    _setLoading(true);
    try {
      final customerId = globalState.filterCustomerId;
      final response = await MachineService.getAll(customerId: customerId);
      if (response['success']) {
        final data = response['data'];
        _allMachines = (data as List).map((e) => Machine.fromJson(e)).toList();
        _filterMachines();
        await _fetchDropdownData(); // Fetch dropdown data for companies and customers
        _errorMessage = null;
      } else {
        _errorMessage = response['error'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void search(String query) {
    _searchQuery = query;
    _filterMachines();
    notifyListeners();
  }

  void _filterMachines() {
    if (_searchQuery.isEmpty) {
      _filteredMachines = List.from(_allMachines);
    } else {
      _filteredMachines = _allMachines.where((machine) {
        return machine.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (machine.serialNo.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            )) ||
            (machine.description?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }
  }

  Future<void> addMachine(Machine machine) async {
    _setLoading(true);
    try {
      final response = await MachineService.create(machine.toJson());
      if (response['success']) {
        await fetchMachines();
      } else {
        _errorMessage = response['error'];
        throw Exception(_errorMessage);
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateMachine(int id, Machine machine) async {
    _setLoading(true);
    try {
      final response = await MachineService.update(id, machine.toJson());
      if (response['success']) {
        await fetchMachines();
      } else {
        _errorMessage = response['error'];
        throw Exception(_errorMessage);
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteMachine(int id) async {
    _setLoading(true);
    try {
      final response = await MachineService.delete(id);
      if (response['success']) {
        await fetchMachines();
      } else {
        _errorMessage = response['error'];
        throw Exception(_errorMessage);
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    if (!_isEditMode) {
      _modifiedMachines.clear();
      fetchMachines();
    }
    notifyListeners();
  }

  void toggleSelection(int id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll(bool select) {
    if (select) {
      _selectedIds.addAll(machines.map((e) => e.id));
    } else {
      _selectedIds.clear();
    }
    notifyListeners();
  }

  void updateLocal(Machine machine) {
    final index = _allMachines.indexWhere((m) => m.id == machine.id);
    if (index != -1) {
      _allMachines[index] = machine;
      _modifiedMachines[machine.id] = machine;
      _filterMachines();
      notifyListeners();
    }
  }

  Future<void> saveChanges() async {
    if (_modifiedMachines.isEmpty) return;
    _setLoading(true);
    try {
      final List<Map<String, dynamic>> updateList = _modifiedMachines.values
          .map((m) => m.toJson())
          .toList();
      final response = await MachineService.updateList(updateList);
      if (response['success']) {
        _modifiedMachines.clear();
        _isEditMode = false;
        await fetchMachines();
      } else {
        _errorMessage = response['error'];
        throw Exception(_errorMessage);
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    _setLoading(true);
    try {
      final response = await MachineService.deleteList(_selectedIds.toList());
      if (response['success']) {
        _selectedIds.clear();
        await fetchMachines();
      } else {
        _errorMessage = response['error'];
        throw Exception(_errorMessage);
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    machineNameController.dispose();
    serialController.dispose();
    descriptionController.dispose();
    companyController.dispose();
    customerController.dispose();
    mqttUsernameController.dispose();
    mqttPasswordController.dispose();
    super.dispose();
  }

  /// Clear all dialog controllers for new entry
  void clearControllers() {
    machineNameController.clear();
    serialController.clear();
    descriptionController.clear();
    companyController.clear();
    customerController.clear();
    mqttUsernameController.clear();
    mqttPasswordController.clear();
    selectedCompanyId = null;
    selectedCustomerId = null;
    _selectedImageBase64 = null;
    _selectedImageName = null;

    // Pre-fill for Customer Admin
    if (globalState.isCustomerUser) {
      final customerId = globalState.filterCustomerId;
      if (customerId != null) {
        selectedCustomerId = customerId;
        // Find name from dropdown if populated
        final customer = dropdownCustomers.firstWhere(
          (c) => c.id == customerId,
          orElse: () => Customer(id: 0, name: ''),
        );
        customerController.text = customer.name ?? '';
      }
    }

    // Eagerly fetch dropdown data if it hasn't been loaded yet
    if (dropdownCompanies.isEmpty || dropdownCustomers.isEmpty) {
      _fetchDropdownData();
    }
    notifyListeners();
  }

  /// Populate controllers with existing machine data for editing
  void populateControllers(Machine machine) {
    machineNameController.text = machine.name;
    serialController.text = machine.serialNo;
    descriptionController.text = machine.description ?? '';
    selectedCompanyId = machine.companyId;
    selectedCustomerId = machine.customerId;
    mqttUsernameController.text = machine.mqttUsername ?? '';
    mqttPasswordController.text = machine.mqttPassword ?? '';

    // Set labels for searchable dropdowns
    companyController.text =
        dropdownCompanies
            .firstWhere(
              (c) => c.id == machine.companyId,
              orElse: () => Company(id: 0, name: ''),
            )
            .name ??
        '';
    customerController.text =
        dropdownCustomers
            .firstWhere(
              (c) => c.id == machine.customerId,
              orElse: () => Customer(id: 0, name: ''),
            )
            .name ??
        '';

    _selectedImageBase64 = machine.image; // Use existing base64 string

    // Eagerly fetch dropdown data if it hasn't been loaded yet
    if (dropdownCompanies.isEmpty || dropdownCustomers.isEmpty) {
      _fetchDropdownData();
    }
    notifyListeners();
  }

  /// SPI-style image picking - returns File object
  Future<File?> chooseImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// SPI-style file to base64 conversion
  Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// Pick image for dialog (combines chooseImage + fileToBase64)
  Future<void> pickImage() async {
    File? file = await chooseImage();
    if (file != null) {
      _selectedImageBase64 = await fileToBase64(file);
      notifyListeners();
    }
  }

  /// Clear the selected image
  void clearImage() {
    _selectedImageBase64 = null;
    _selectedImageName = null;
    notifyListeners();
  }

  /// Fetch dropdown data for companies and customers
  Future<void> _fetchDropdownData() async {
    try {
      // Fetch companies
      final companyResponse = await CompanyService.getAll();
      if (companyResponse['success']) {
        dropdownCompanies = (companyResponse['data'] as List)
            .map((e) => Company.fromJson(e))
            .toList();
      }

      // Fetch customers
      final response = await CustomerService.getAll();
      if (response['success']) {
        List<Customer> allCustomers = (response['data'] as List)
            .map((e) => Customer.fromJson(e))
            .toList();

        // Filter if Customer Admin
        if (globalState.isCustomerUser && globalState.filterCustomerId != null) {
          dropdownCustomers = allCustomers.where((c) => c.id == globalState.filterCustomerId).toList();
        } else {
          dropdownCustomers = allCustomers;
        }
      }

      notifyListeners();
    } catch (e) {
      // Silently fail - dropdowns will be empty but won't crash the app
      debugPrint('Error fetching dropdown data: $e');
    }
  }
}
