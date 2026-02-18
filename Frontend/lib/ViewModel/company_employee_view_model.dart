import 'package:flutter/material.dart';
import '../Models/company.dart';
import '../Models/company_employee.dart';
import '../Services/employee_service.dart';
import '../Services/company_service.dart';
import 'global_state.dart';

class CompanyEmployeeViewModel extends ChangeNotifier {
  final GlobalState globalState = GlobalState();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController employeeIdController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController companyController = TextEditingController();

  int? selectedCompanyId;
  String? selectedPrivilege;
  String? selectedStatus;

  List<CompanyEmployee> _allEmployees = [];
  List<CompanyEmployee> _filteredEmployees = [];
  String _searchQuery = '';

  bool _isLoading = false;
  String? _errorMessage;
  final Set<int> _selectedIds = {};
  bool _isEditMode = false;

  final Map<int, CompanyEmployee> _modifiedEmployees = {};

  // Dropdown data - fetched directly from services
  List<Company> dropdownCompanies = [];

  List<CompanyEmployee> get employees => _searchQuery.isEmpty
      ? _allEmployees
      : _filteredEmployees;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEditMode => _isEditMode;
  Set<int> get selectedIds => _selectedIds;

  Future<void> fetchEmployees() async {
    _setLoading(true);
    try {
      final response = await EmployeeService.getCompanyEmployees();
      if (response['success']) {
        final data = response['data'];
        _allEmployees = (data as List)
            .map((e) => CompanyEmployee.fromJson(e))
            .toList();
        _filterEmployees();
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

  void searchEmployees(String query) {
    _searchQuery = query;
    _filterEmployees();
    notifyListeners();
  }

  void _filterEmployees() {
    if (_searchQuery.isEmpty) {
      _filteredEmployees = List.from(_allEmployees);
    } else {
      _filteredEmployees = _allEmployees.where((e) {
        return (e.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (e.username.toLowerCase().contains(_searchQuery.toLowerCase())) ||
            (e.employeeId.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
  }

  Future<void> addEmployee(CompanyEmployee employee, String password) async {
    _setLoading(true);
    try {
      final data = employee.toJson();
      data['Password'] = password;
      final response = await EmployeeService.addCompanyEmployee(data);
      if (response['success']) {
        await fetchEmployees();
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

  Future<void> updateEmployee(int id, CompanyEmployee employee, {String? password}) async {
    _setLoading(true);
    try {
      final data = employee.toJson();
      if (password != null && password.isNotEmpty) {
        data['Password'] = password;
      }
      final response = await EmployeeService.updateCompanyEmployee(id, data);
      if (response['success']) {
        await fetchEmployees();
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
      final response = await EmployeeService.deleteCompanyEmployees(_selectedIds.toList());
      if (response['success']) {
        _selectedIds.clear();
        await fetchEmployees();
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
      _modifiedEmployees.clear();
      fetchEmployees();
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
      _selectedIds.addAll(employees.map((e) => e.id));
    } else {
      _selectedIds.clear();
    }
    notifyListeners();
  }

  void updateLocal(CompanyEmployee employee) {
    final index = _allEmployees.indexWhere((e) => e.id == employee.id);
    if (index != -1) {
      _allEmployees[index] = employee;
      _modifiedEmployees[employee.id] = employee;
      _filterEmployees();
      notifyListeners();
    }
  }

  Future<void> saveBulkChanges() async {
    if (_modifiedEmployees.isEmpty) return;
    _setLoading(true);
    try {
      final List<Map<String, dynamic>> updateList = _modifiedEmployees.values.map((e) => e.toJson()).toList();
      final response = await EmployeeService.updateCompanyEmployees(updateList);
      if (response['success']) {
        _modifiedEmployees.clear();
        await fetchEmployees();
        _isEditMode = false;
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

  void clearControllers() {
    nameController.clear();
    employeeIdController.clear();
    emailController.clear();
    usernameController.clear();
    passwordController.clear();
    companyController.clear();
    selectedCompanyId = null;
    selectedPrivilege = null;
    selectedStatus = 'Active';
  }

  void populateControllers(CompanyEmployee employee) {
    nameController.text = employee.name ?? '';
    employeeIdController.text = employee.employeeId;
    emailController.text = employee.email ?? '';
    usernameController.text = employee.username;
    passwordController.clear();
    selectedCompanyId = employee.companyId;
    companyController.text = dropdownCompanies
            .firstWhere((c) => c.id == employee.companyId, orElse: () => Company(id: 0, name: ''))
            .name ?? '';
    selectedPrivilege = employee.privilege;
    selectedStatus = employee.status;
  }

  void setSelectedCompany(int? id) { selectedCompanyId = id; notifyListeners(); }
  void setSelectedPrivilege(String? p) { selectedPrivilege = p; notifyListeners(); }
  void setSelectedStatus(String? s) { selectedStatus = s; notifyListeners(); }

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
      debugPrint('Error fetching dropdown companies: $e');
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    employeeIdController.dispose();
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    companyController.dispose();
    super.dispose();
  }
}
