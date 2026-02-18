import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // To pick images
import 'dart:convert'; // To encode image to base64
import 'dart:io'; // To read file
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List; // To check web
import '../Models/company.dart';
import '../Models/customer.dart';
import '../Services/customer_service.dart';
import '../Services/company_service.dart';
import 'global_state.dart';

class CustomerViewModel extends ChangeNotifier {
  // Global state reference
  final GlobalState globalState = GlobalState();

  // TextEditingControllers for Add/Edit dialog
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController companyController = TextEditingController();

  String? _selectedImageBase64;
  String? get selectedImageBase64 => _selectedImageBase64;
  String? _selectedImageName; // for UI display if needed

  // Selected company ID for dropdown
  int? selectedCompanyId;

  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  final Set<int> _selectedIds = {};
  bool _isEditMode = false;
  final Map<int, Customer> _modifiedCustomers = {};

  // Dropdown data - fetched directly from services
  List<Company> dropdownCompanies = [];

  List<Customer> get customers =>
      _searchQuery.isEmpty ? _allCustomers : _filteredCustomers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEditMode => _isEditMode;
  Set<int> get selectedIds => _selectedIds;

  Future<void> fetchCustomers() async {
    _setLoading(true);
    try {
      final customerId = globalState.filterCustomerId;
      final response = await CustomerService.getAll(customerId: customerId);
      if (response['success']) {
        final data = response['data'];
        _allCustomers = (data as List)
            .map((e) => Customer.fromJson(e))
            .toList();
        _filterCustomers();
        await _fetchDropdownCompanies(); // Fetch dropdown data for companies
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
    _filterCustomers();
    notifyListeners();
  }

  void _filterCustomers() {
    if (_searchQuery.isEmpty) {
      _filteredCustomers = List.from(_allCustomers);
    } else {
      _filteredCustomers = _allCustomers.where((customer) {
        return customer.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ) ||
            (customer.address?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }
  }

  Future<void> addCustomer(Customer customer) async {
    _setLoading(true);
    try {
      final response = await CustomerService.create(customer.toJson());
      if (response['success']) {
        await fetchCustomers();
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

  Future<void> updateCustomer(int id, Customer customer) async {
    _setLoading(true);
    try {
      final response = await CustomerService.update(id, customer.toJson());
      if (response['success']) {
        await fetchCustomers();
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

  Future<void> deleteCustomer(int id) async {
    _setLoading(true);
    try {
      final response = await CustomerService.delete(id);
      if (response['success']) {
        await fetchCustomers();
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
      _modifiedCustomers.clear();
      fetchCustomers();
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
      _selectedIds.addAll(customers.map((e) => e.id));
    } else {
      _selectedIds.clear();
    }
    notifyListeners();
  }

  void updateLocal(Customer customer) {
    final index = _allCustomers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _allCustomers[index] = customer;
      _modifiedCustomers[customer.id] = customer;
      _filterCustomers();
      notifyListeners();
    }
  }

  Future<void> saveChanges() async {
    if (_modifiedCustomers.isEmpty) return;

    _setLoading(true);
    try {
      final List<Map<String, dynamic>> updateList = _modifiedCustomers.values
          .map((c) => c.toJson())
          .toList();
      final response = await CustomerService.updateList(updateList);
      if (response['success']) {
        _modifiedCustomers.clear();
        _isEditMode = false;
        await fetchCustomers();
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
      final response = await CustomerService.deleteList(_selectedIds.toList());
      if (response['success']) {
        _selectedIds.clear();
        await fetchCustomers();
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

  /// Clear all dialog controllers for new entry
  void clearControllers() {
    customerNameController.clear();
    addressController.clear();
    locationController.clear();
    companyController.clear();
    selectedCompanyId = null;
    _selectedImageBase64 = null;
    _selectedImageName = null;
    notifyListeners();
  }

  /// Populate controllers with existing customer data for editing
  void populateControllers(Customer customer) {
    customerNameController.text = customer.name;
    addressController.text = customer.address ?? '';
    locationController.text = customer.location ?? '';
    selectedCompanyId = customer.companyId;

    // Set label for searchable dropdown
    companyController.text =
        dropdownCompanies
            .firstWhere(
              (c) => c.id == customer.companyId,
              orElse: () => Company(id: 0, name: ''),
            )
            .name ??
        '';

    _selectedImageBase64 = customer.image; // Use existing base64 string
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

  /// Set selected company ID and notify listeners
  void setSelectedCompany(int? companyId) {
    selectedCompanyId = companyId;
    notifyListeners();
  }

  /// Fetch dropdown data for companies
  Future<void> _fetchDropdownCompanies() async {
    try {
      final companyResponse = await CompanyService.getAll();
      if (companyResponse['success']) {
        dropdownCompanies = (companyResponse['data'] as List)
            .map((e) => Company.fromJson(e))
            .toList();
      }
      notifyListeners();
    } catch (e) {
      // Silently fail - dropdowns will be empty but won't crash the app
      debugPrint('Error fetching dropdown companies: $e');
    }
  }

  @override
  void dispose() {
    customerNameController.dispose();
    addressController.dispose();
    locationController.dispose();
    companyController.dispose();
    super.dispose();
  }
}
