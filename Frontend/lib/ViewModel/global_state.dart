import 'package:flutter/material.dart';
import '../Services/auth_service.dart';
import '../Models/company.dart';
import '../Models/customer.dart';
import '../Models/machine.dart';
import '../Models/user.dart';

/// Global state singleton to hold shared application data
/// Used for dropdown lists and shared configuration across the app
class GlobalState extends ChangeNotifier {
  // Singleton pattern
  static final GlobalState _instance = GlobalState._internal();

  factory GlobalState() {
    return _instance;
  }

  // Private constructor
  GlobalState._internal();

  /// Available privilege levels for employees
  List<String> privilegeOptions = ['Admin', 'User'];

  /// Available status options
  List<String> statusOptions = ['Active', 'Inactive'];

  /// Current application language
  String language = 'en';

  /// Current logged-in user
  User? _currentUser;
  User? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isLoggedIn => _currentUser != null;

  /// Check if user is a Company Employee
  bool get isCompanyEmployee => _currentUser?.isCompanyEmployee ?? false;

  /// Check if user is a Customer User
  bool get isCustomerUser => _currentUser?.isCustomerUser ?? false;

  /// Check if user has Admin privilege
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Check if user has User privilege
  bool get isUser => _currentUser?.isUser ?? false;

  /// Set the current user after login
  void setUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Clear user session (logout)
  void logout() {
    AuthService.logout();
    _currentUser = null;
    notifyListeners();
  }

  /// Check for saved session on app start
  Future<bool> checkAutoLogin() async {
    final user = await AuthService.getSavedUser();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Get customer ID for filtering (null for Company Employees)
  int? get filterCustomerId {
    if (isCustomerUser) {
      return _currentUser?.customerId;
    }
    return null; // Company Employees see all customers
  }
}
