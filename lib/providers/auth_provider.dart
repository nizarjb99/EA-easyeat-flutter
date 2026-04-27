import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/employee.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthAccountType { none, customer, employee }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser; // kept for compatibility with your old screens
  Customer? _currentCustomer;
  Employee? _currentEmployee;
  Map<String, dynamic>? _restaurant;

  String? _accessToken;
  AuthAccountType _accountType = AuthAccountType.none;
  bool _isLoading = false;
  String _errorMessage = '';

  User? get currentUser => _currentUser;
  User? get user => _currentUser; // alias, useful for new screens
  Customer? get currentCustomer => _currentCustomer;
  Employee? get currentEmployee => _currentEmployee;
  Map<String, dynamic>? get restaurant => _restaurant;

  String? get accessToken => _accessToken;
  String? get token => _accessToken;
  AuthAccountType get accountType => _accountType;

  bool get isLoggedIn => _accessToken != null && (_currentCustomer != null || _currentEmployee != null || _currentUser != null);
  bool get isCustomer => _accountType == AuthAccountType.customer;
  bool get isEmployee => _accountType == AuthAccountType.employee;
  bool get isOwner => _currentEmployee?.role == 'owner';
  bool get isStaff => _currentEmployee?.role == 'staff';

  /// Final role used by the router:
  /// - customer login returns 'customer'
  /// - employee login returns employee.profile.role: 'owner' or 'staff'
  String? get role {
    if (isCustomer) return 'customer';
    if (isEmployee) return _currentEmployee?.role;
    return null;
  }

  String get displayName {
    if (isCustomer) return _currentCustomer?.name ?? _currentUser?.name ?? 'Cliente';
    if (isEmployee) return _currentEmployee?.name ?? _currentUser?.name ?? 'Empleado';
    return _currentUser?.name ?? 'Usuario';
  }

  String? get email {
    if (isCustomer) return _currentCustomer?.email ?? _currentUser?.email;
    if (isEmployee) return _currentEmployee?.email ?? _currentUser?.email;
    return _currentUser?.email;
  }

  String? get id {
    if (isCustomer) return _currentCustomer?.id ?? _currentUser?.id;
    if (isEmployee) return _currentEmployee?.id ?? _currentUser?.id;
    return _currentUser?.id;
  }

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  void logout() {
    _currentUser = null;
    _currentCustomer = null;
    _currentEmployee = null;
    _restaurant = null;
    _accessToken = null;
    _accountType = AuthAccountType.none;
    _errorMessage = '';
    notifyListeners();
  }

  Future<bool> login(String email, String password, {String role = 'employee'}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Map<String, dynamic> response = await _authService.login(
        email.trim(),
        password.trim(),
        role: role,
      );

      _accessToken = (response['accessToken'] ?? response['token'])?.toString();

      final dynamic rawCustomer = response['customer'];
      final dynamic rawEmployee = response['employee'];
      final dynamic rawAdmin = response['admin'];
      final dynamic rawUser = response['user'] ?? response['usuario'];
      final dynamic rawRestaurant = response['restaurant'];

      _currentCustomer = null;
      _currentEmployee = null;
      _restaurant = rawRestaurant is Map<String, dynamic> ? rawRestaurant : null;

      if (rawCustomer is Map<String, dynamic>) {
        _accountType = AuthAccountType.customer;
        _currentCustomer = Customer.fromJson(rawCustomer);
        _currentUser = _safeUserFromJson(rawCustomer);
      } else if (rawEmployee is Map<String, dynamic>) {
        _accountType = AuthAccountType.employee;
        _currentEmployee = Employee.fromJson(rawEmployee);
        _currentUser = _userFromEmployee(_currentEmployee!);
      } else if (rawAdmin is Map<String, dynamic>) {
        // Optional compatibility if your backend ever returns admin.
        _accountType = AuthAccountType.employee;
        _currentEmployee = Employee.fromJson(rawAdmin);
        _currentUser = _userFromEmployee(_currentEmployee!);
      } else if (rawUser is Map<String, dynamic>) {
        // Fallback for old backend responses.
        if (role == 'customer') {
          _accountType = AuthAccountType.customer;
          _currentCustomer = Customer.fromJson(rawUser);
        } else {
          _accountType = AuthAccountType.employee;
          _currentEmployee = Employee.fromJson(rawUser);
        }
        _currentUser = _safeUserFromJson(rawUser);
      } else {
        throw Exception('Unexpected server response: missing customer/employee data');
      }

      if (_accessToken == null || _accessToken!.isEmpty) {
        throw Exception('Unexpected server response: missing access token');
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _authService.signup(name, email.trim(), password.trim());
      return await login(email, password, role: 'customer');
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> loadProfileFromApi() async {
    if (id == null || _accessToken == null || _accessToken!.isEmpty) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Map<String, dynamic> rawUser = await _authService.fetchUserById(id!, _accessToken!);

      if (isCustomer) {
        _currentCustomer = Customer.fromJson(rawUser);
        _currentUser = _safeUserFromJson(rawUser);
      } else if (isEmployee) {
        _currentEmployee = Employee.fromJson(rawUser);
        _currentUser = _userFromEmployee(_currentEmployee!);
      } else {
        _currentUser = _safeUserFromJson(rawUser);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  User _safeUserFromJson(Map<String, dynamic> json) {
    return User.fromJson(json);
  }

  User _userFromEmployee(Employee employee) {
    return User.fromJson({
      '_id': employee.id,
      'id': employee.id,
      'name': employee.name,
      'email': employee.email ?? '',
    });
  }
}
