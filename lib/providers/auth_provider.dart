import 'package:flutter/material.dart';

import '../models/customer.dart';
import '../models/employee.dart';
import '../services/auth_service.dart';
import '../services/customer_service.dart';
import '../services/employee_service.dart';
import '../services/restaurant_service.dart';

enum AuthAccountType { none, customer, employee }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final CustomerService _customerService = CustomerService();
  final EmployeeService _employeeService = EmployeeService();

  Customer? _currentCustomer;
  Employee? _currentEmployee;
  Map<String, dynamic>? _restaurant;

  String? _accessToken;
  AuthAccountType _accountType = AuthAccountType.none;
  bool _isLoading = false;
  String _errorMessage = '';

  Customer? get currentCustomer => _currentCustomer;
  Employee? get currentEmployee => _currentEmployee;
  Map<String, dynamic>? get restaurant => _restaurant;

  String? get accessToken => _accessToken;
  String? get token => _accessToken;
  AuthAccountType get accountType => _accountType;

  bool get isLoggedIn => _accessToken != null && (_currentCustomer != null || _currentEmployee != null);
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
    if (isCustomer) return _currentCustomer?.name ?? 'Cliente';
    if (isEmployee) return _currentEmployee?.name ?? 'Empleado';
    return 'Usuario';
  }

  String? get email {
    if (isCustomer) return _currentCustomer?.email;
    if (isEmployee) return _currentEmployee?.email;
    return null;
  }

  String? get id {
    if (isCustomer) return _currentCustomer?.id;
    if (isEmployee) return _currentEmployee?.id;
    return null;
  }

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  void logout() {
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

      _currentCustomer = null;
      _currentEmployee = null;

      final dynamic rawRestaurant = response['restaurant'];
      Map<String, dynamic>? normalizedRestaurant;

      if (rawRestaurant is Map<String, dynamic>) {
        normalizedRestaurant = rawRestaurant;
      } else if (rawRestaurant is String) {
        normalizedRestaurant = {'id': rawRestaurant};
      } else {
        // maybe the restaurant is included inside employee/user object
        final dynamic maybeUser = rawEmployee ?? rawUser;
        if (maybeUser is Map<String, dynamic>) {
          final empRest = maybeUser['restaurant'] ?? maybeUser['restaurant_id'] ?? maybeUser['restaurantId'];
          if (empRest is Map<String, dynamic>) {
            normalizedRestaurant = empRest;
          } else if (empRest is String) {
            normalizedRestaurant = {'id': empRest};
          }
        }
      }

      _restaurant = normalizedRestaurant;

      if (rawCustomer is Map<String, dynamic>) {
        _accountType = AuthAccountType.customer;
        _currentCustomer = Customer.fromJson(rawCustomer);
      }
      else if (rawEmployee is Map<String, dynamic>) {
        _accountType = AuthAccountType.employee;
        _currentEmployee = Employee.fromJson(rawEmployee);
      }
      else if (rawAdmin is Map<String, dynamic>) {
        // Optional compatibility if your backend ever returns admin.
        _accountType = AuthAccountType.employee;
        _currentEmployee = Employee.fromJson(rawAdmin);
      }
      else if (rawUser is Map<String, dynamic>) {
        // Fallback for old backend responses.
        if (role == 'customer') {
          _accountType = AuthAccountType.customer;
          _currentCustomer = Customer.fromJson(rawUser);
        } else {
          _accountType = AuthAccountType.employee;
          _currentEmployee = Employee.fromJson(rawUser);
        }
      } else {
        throw Exception('Unexpected server response: missing customer/employee data');
      }

      if (_accessToken == null || _accessToken!.isEmpty) {
        throw Exception('Unexpected server response: missing access token');
      }

      if (isEmployee && _currentEmployee != null) {
        try {
          final restaurantService = RestaurantService();
          final fullRestaurant = await restaurantService.fetchFullRestaurantById(
            _currentEmployee!.restaurantId,
            accessToken: _accessToken,
          );
          _restaurant = fullRestaurant;
        } catch (e) {
          debugPrint('Error fetching full restaurant: $e');
        }
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
      if (isCustomer) {
        final Map<String, dynamic> rawUser = await _authService.fetchCustomerById(id!, _accessToken!);
        final data = rawUser['data'] ?? rawUser;
        _currentCustomer = Customer.fromJson(data);
      } else if (isEmployee) {
        final Map<String, dynamic> rawUser = await _authService.fetchEmployeeById(id!, _accessToken!);
        final data = rawUser['data'] ?? rawUser;
        _currentEmployee = Employee.fromJson(data);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    if (!isLoggedIn || id == null || _accessToken == null || _accessToken!.isEmpty) {
      throw Exception('User session not found');
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (isCustomer && _currentCustomer != null) {
        final updatedCustomer = await _customerService.updateCustomer(
          id!,
          <String, dynamic>{
            'name': name.trim(),
            'email': email.trim(),
          },
          _accessToken!,
        );
        _currentCustomer = updatedCustomer;
      } else if (isEmployee && _currentEmployee != null) {
        final updatedEmployee = await _employeeService.updateEmployee(
          id!,
          <String, dynamic>{
            'profile': <String, dynamic>{
              'name': name.trim(),
              'email': email.trim(),
              if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
            },
          },
          accessToken: _accessToken,
        );
        _currentEmployee = updatedEmployee;
      } else {
        throw Exception('Unsupported account type');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }
}
