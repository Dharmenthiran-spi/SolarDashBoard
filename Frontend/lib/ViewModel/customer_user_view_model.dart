import 'package:flutter/material.dart';
import '../Models/customer.dart';
import '../Models/customer_user.dart';
import '../Services/employee_service.dart';
import '../Services/customer_service.dart';
import 'global_state.dart';

class CustomerUserViewModel extends ChangeNotifier {
  final GlobalState globalState = GlobalState();

  final TextEditingController companyNameController = TextEditingController(); // Not used but kept for consistency if needed or removal
  final TextEditingController customerNameController = TextEditingController(); // User's Name
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController customerController = TextEditingController();

  int? selectedCustomerId;
  String? selectedPrivilege;
  String? selectedStatus;

  List<CustomerUser> _allUsers = [];
  List<CustomerUser> _filteredUsers = [];
  String _searchQuery = '';

  bool _isLoading = false;
  String? _errorMessage;
  final Set<int> _selectedIds = {};
  bool _isEditMode = false;

  final Map<int, CustomerUser> _modifiedUsers = {};

  // Dropdown data - fetched directly from services
  List<Customer> dropdownCustomers = [];

  List<CustomerUser> get users => _searchQuery.isEmpty
      ? _allUsers
      : _filteredUsers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEditMode => _isEditMode;
  Set<int> get selectedIds => _selectedIds;

  Future<void> fetchUsers() async {
    _setLoading(true);
    try {
      final customerId = globalState.filterCustomerId;
      final response = await EmployeeService.getCustomerUsers(customerId: customerId);
      if (response['success']) {
        final data = response['data'];
        _allUsers = (data as List)
            .map((e) => CustomerUser.fromJson(e))
            .toList();
        _filterUsers();
        await _fetchDropdownCustomers(); // Fetch dropdown data for customers
        
        // If Customer Admin, set selectedCustomerId automatically for new users
        if (globalState.isCustomerUser && customerId != null) {
          selectedCustomerId = customerId;
        }

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

  void searchUsers(String query) {
    _searchQuery = query;
    _filterUsers();
    notifyListeners();
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_allUsers);
    } else {
      _filteredUsers = _allUsers.where((e) {
        return (e.customerName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (e.organizationName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (e.companyName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (e.username.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
  }

  Future<void> addUser(CustomerUser user, String password) async {
    _setLoading(true);
    try {
      final data = user.toJson();
      data['Password'] = password;
      final response = await EmployeeService.addCustomerUser(data);
      if (response['success']) {
        await fetchUsers();
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

  Future<void> updateUser(int id, CustomerUser user, {String? password}) async {
    _setLoading(true);
    try {
      final data = user.toJson();
      if (password != null && password.isNotEmpty) {
        data['Password'] = password;
      }
      final response = await EmployeeService.updateCustomerUser(id, data);
      if (response['success']) {
        await fetchUsers();
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
      final response = await EmployeeService.deleteCustomerUsers(_selectedIds.toList());
      if (response['success']) {
        _selectedIds.clear();
        await fetchUsers();
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
      _modifiedUsers.clear();
      fetchUsers();
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
      _selectedIds.addAll(users.map((e) => e.id));
    } else {
      _selectedIds.clear();
    }
    notifyListeners();
  }

  void updateLocal(CustomerUser user) {
    final index = _allUsers.indexWhere((e) => e.id == user.id);
    if (index != -1) {
      _allUsers[index] = user;
      _modifiedUsers[user.id] = user;
      _filterUsers();
      notifyListeners();
    }
  }

  Future<void> saveBulkChanges() async {
    if (_modifiedUsers.isEmpty) return;
    _setLoading(true);
    try {
      final List<Map<String, dynamic>> updateList = _modifiedUsers.values.map((e) => e.toJson()).toList();
      final response = await EmployeeService.updateCustomerUsers(updateList);
      if (response['success']) {
        _modifiedUsers.clear();
        await fetchUsers();
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
    customerNameController.clear();
    usernameController.clear();
    passwordController.clear();
    customerController.clear();
    selectedCustomerId = null;
    selectedPrivilege = null;
    selectedStatus = 'Active';

    // Pre-fill for Customer Admin
    if (globalState.isCustomerUser) {
      final customerId = globalState.filterCustomerId;
      if (customerId != null) {
        selectedCustomerId = customerId;
        // Find name from dropdown (should be populated)
        final customer = dropdownCustomers.firstWhere(
          (c) => c.id == customerId, 
          orElse: () => Customer(id: 0, name: '')
        );
        customerController.text = customer.name ?? '';
      }
    }
  }

  void populateControllers(CustomerUser user) {
    customerNameController.text = user.customerName ?? '';
    usernameController.text = user.username;
    passwordController.clear();
    selectedCustomerId = user.customerId;
    customerController.text = dropdownCustomers
            .firstWhere((c) => c.id == user.customerId, orElse: () => Customer(id: 0, name: ''))
            .name ?? '';
    selectedPrivilege = user.privilege;
    selectedStatus = user.status;
  }

  void setSelectedCustomer(int? id) { selectedCustomerId = id; notifyListeners(); }
  void setSelectedPrivilege(String? p) { selectedPrivilege = p; notifyListeners(); }
  void setSelectedStatus(String? s) { selectedStatus = s; notifyListeners(); }

  /// Fetch dropdown data for customers
  Future<void> _fetchDropdownCustomers() async {
    try {
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
      debugPrint('Error fetching dropdown customers: $e');
    }
  }

  @override
  void dispose() {
    customerNameController.dispose();
    companyNameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    customerController.dispose();
    super.dispose();
  }
}
