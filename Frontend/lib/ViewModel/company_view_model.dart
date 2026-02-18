import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // To pick images
import 'dart:convert'; // To encode image to base64
import 'dart:io'; // To read file
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List; // To check web
import '../Models/company.dart';
import '../Services/company_service.dart';
import 'global_state.dart';

class CompanyViewModel extends ChangeNotifier {
  // Global state reference
  final GlobalState globalState = GlobalState();

  // TextEditingControllers for Add/Edit dialog
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  String? _selectedImageBase64;
  String? get selectedImageBase64 => _selectedImageBase64;
  String? _selectedImageName; // for UI display if needed

  List<Company> _allCompanies = [];
  List<Company> _filteredCompanies = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  final Set<int> _selectedIds = {};
  bool _isEditMode = false;
  final Map<int, Company> _modifiedCompanies = {};

  List<Company> get companies =>
      _searchQuery.isEmpty ? _allCompanies : _filteredCompanies;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<int> get selectedIds => _selectedIds;
  bool get isEditMode => _isEditMode;

  Future<void> fetchCompanies() async {
    _setLoading(true);
    try {
      final response = await CompanyService.getAll();
      if (response['success']) {
        final data = response['data'];
        _allCompanies = (data as List)
            .map((item) => Company.fromJson(item))
            .toList();
        _filterCompanies();
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
    _filterCompanies();
    notifyListeners();
  }

  void _filterCompanies() {
    if (_searchQuery.isEmpty) {
      _filteredCompanies = List.from(_allCompanies);
    } else {
      _filteredCompanies = _allCompanies
          .where(
            (company) =>
                company.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (company.address?.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }
  }

  Future<void> addCompany(Company company) async {
    _setLoading(true);
    try {
      final response = await CompanyService.create(company.toJson());
      if (response['success']) {
        await fetchCompanies();
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

  Future<void> updateCompany(int id, Company company) async {
    _setLoading(true);
    try {
      final response = await CompanyService.update(id, company.toJson());
      if (response['success']) {
        await fetchCompanies();
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

  Future<void> deleteCompany(int id) async {
    _setLoading(true);
    try {
      final response = await CompanyService.delete(id);
      if (response['success']) {
        await fetchCompanies();
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
      _modifiedCompanies.clear();
      fetchCompanies();
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

  void selectAll(bool selected) {
    if (selected) {
      _selectedIds.addAll(companies.map((c) => c.id));
    } else {
      _selectedIds.clear();
    }
    notifyListeners();
  }

  void updateLocal(Company company) {
    final index = _allCompanies.indexWhere((c) => c.id == company.id);
    if (index != -1) {
      _allCompanies[index] = company;
      _modifiedCompanies[company.id] = company;
      _filterCompanies();
      notifyListeners();
    }
  }

  Future<void> saveChanges() async {
    if (_modifiedCompanies.isEmpty) return;

    _setLoading(true);
    try {
      final List<Map<String, dynamic>> updateList = _modifiedCompanies.values
          .map((c) => c.toJson())
          .toList();
      final response = await CompanyService.updateList(updateList);
      if (response['success']) {
        _modifiedCompanies.clear();
        _isEditMode = false;
        await fetchCompanies();
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
      final response = await CompanyService.deleteList(_selectedIds.toList());
      if (response['success']) {
        _selectedIds.clear();
        await fetchCompanies();
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
    companyNameController.clear();
    addressController.clear();
    locationController.clear();
    _selectedImageBase64 = null;
    _selectedImageName = null;
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

  @override
  void dispose() {
    companyNameController.dispose();
    addressController.dispose();
    locationController.dispose();
    super.dispose();
  }
}
