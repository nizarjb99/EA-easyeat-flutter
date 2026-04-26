import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  String? _accessToken;
  bool _isLoading = false;
  String _errorMessage = '';

  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  void logout() {
    _currentUser = null;
    _accessToken = null;
    _errorMessage = '';
    notifyListeners();
  }

  Future<bool> login(String email, String password, {String role = 'employee'}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // Backend response: { message, accessToken, employee: { ... } }
      final Map<String, dynamic> response =
      await _authService.login(email.trim(), password.trim(), role: role);

      _accessToken = response['accessToken'] as String?;

      // Look for employee, admin, or customer key
      final dynamic rawUser = response['employee'] ?? response['admin'] ?? response['customer'] ?? response['usuario'];
      
      if (rawUser == null || rawUser is! Map<String, dynamic>) {
        throw Exception('Unexpected server response: missing user data');
      }

      _currentUser = User.fromJson(rawUser);
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

  Future<bool> signup(
      String name,
      String email,
      String password,
      ) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Map<String, dynamic> response = await _authService.signup(
        name,
        email.trim(),
        password.trim(),
      );

      // After successful registration, we perform auto-login like the React app
      return await login(email, password, role: 'customer');
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }


  Future<void> loadProfileFromApi() async {
    if (_currentUser == null || _accessToken == null || _accessToken!.isEmpty) {
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final Map<String, dynamic> rawUser = await _authService.fetchUserById(
        _currentUser!.id,
        _accessToken!,
      );

      _currentUser = User.fromJson(rawUser);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
