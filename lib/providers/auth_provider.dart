import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/customer.dart';
import '../models/employee.dart';
import '../services/auth_service.dart';
import '../services/customer_service.dart';
import '../services/employee_service.dart';
import '../services/fcm_service.dart';
import '../services/restaurant_service.dart';

enum AuthAccountType { none, customer, employee }

class AuthProvider extends ChangeNotifier {
  AuthProvider({FcmService? fcmService})
      : _fcmService = fcmService ?? FcmService();

  final AuthService _authService = AuthService();
  final CustomerService _customerService = CustomerService();
  final EmployeeService _employeeService = EmployeeService();
  final FcmService _fcmService;
  bool _googleSignInInitialized = false;

  Customer? _currentCustomer;
  Employee? _currentEmployee;
  Map<String, dynamic>? _restaurant;

  String? _accessToken;
  AuthAccountType _accountType = AuthAccountType.none;
  bool _isLoading = true;
  String _errorMessage = '';

  // ── Getters ────────────────────────────────────────────────────────────────

  Customer? get currentCustomer => _currentCustomer;
  Employee? get currentEmployee => _currentEmployee;
  Map<String, dynamic>? get restaurant => _restaurant;

  String? get accessToken => _accessToken;
  String? get token => _accessToken;
  AuthAccountType get accountType => _accountType;

  bool get isLoggedIn =>
      _accessToken != null &&
          (_currentCustomer != null || _currentEmployee != null);

  bool get isCustomer => _accountType == AuthAccountType.customer;
  bool get isEmployee => _accountType == AuthAccountType.employee;
  bool get isOwner => _currentEmployee?.role == 'owner';
  bool get isStaff => _currentEmployee?.role == 'staff';

  /// Final role used by the router:
  /// - customer login → 'customer'
  /// - employee login → employee.profile.role: 'owner' | 'staff'
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

  // ──────────────────────────────────────────────────────────────────────────
  // Session restore
  // ──────────────────────────────────────────────────────────────────────────

  /// Attempts to restore a previously saved session from SharedPreferences.
  /// If the token has expired, tries to refresh it via /auth/refresh.
  /// Initialises FCM if the session is restored successfully.
  /// Returns `true` if the session was restored successfully.
Future<bool> tryRestoreSession() async {
  // Idempotency guard: don't run while a restore is already in progress,
  // and don't run again if the session is already established.
  if (!_isLoading && isLoggedIn) return true;

  _isLoading = true;
  notifyListeners();
  try {
    final savedToken = await _authService.getAccessToken();
    final savedUserId = await _authService.getUserId();
    final savedRole = await _authService.getUserRole();

    if (savedToken == null ||
        savedToken.isEmpty ||
        savedUserId == null ||
        savedUserId.isEmpty ||
        savedRole == null ||
        savedRole.isEmpty) {
      return false;  // finally s'encarregarà de _isLoading = false
    }

      _accessToken = savedToken;

      // Try to fetch the user profile. If it fails (e.g. 401),
      // attempt a token refresh and retry once.
      try {
        await _fetchUserProfile(savedUserId, savedRole, savedToken);
      } catch (e) {
        debugPrint('Profile fetch failed, attempting token refresh: $e');

        final newToken = await _authService.refreshToken(savedToken);
        if (newToken == null) {
          debugPrint('Token refresh failed, clearing session.');
          await _authService.logout();
          _resetSessionState();
          return false;
        }

        _accessToken = newToken;
        await _fetchUserProfile(savedUserId, savedRole, newToken);
      }

      notifyListeners();

      // Initialise FCM now that we know who the user is.
      // For employees we skip FCM (notifications are customer-only).
      if (isCustomer) {
        await _initFcm();
      }

      return true;
    } 
    catch (e) {
      debugPrint('Session restore failed: $e');
      await _authService.logout();
      _resetSessionState();
      return false;
    } 
    finally {
    _isLoading = false;      // ← s'executa SEMPRE, sigui quin sigui el camí
    notifyListeners();
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Login
  // ──────────────────────────────────────────────────────────────────────────

  Future<bool> login(
      String email,
      String password, {
        String role = 'employee',
      }) async {
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
        final dynamic maybeUser = rawEmployee ?? rawUser;
        if (maybeUser is Map<String, dynamic>) {
          final empRest = maybeUser['restaurant'] ??
              maybeUser['restaurant_id'] ??
              maybeUser['restaurantId'];
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
      } else if (rawEmployee is Map<String, dynamic>) {
        _accountType = AuthAccountType.employee;
        _currentEmployee = Employee.fromJson(rawEmployee);
      } else if (rawAdmin is Map<String, dynamic>) {
        _accountType = AuthAccountType.employee;
        _currentEmployee = Employee.fromJson(rawAdmin);
      } else if (rawUser is Map<String, dynamic>) {
        if (role == 'customer') {
          _accountType = AuthAccountType.customer;
          _currentCustomer = Customer.fromJson(rawUser);
        } else {
          _accountType = AuthAccountType.employee;
          _currentEmployee = Employee.fromJson(rawUser);
        }
      } else {
        throw Exception(
            'Unexpected server response: missing customer/employee data');
      }

      if (_accessToken == null || _accessToken!.isEmpty) {
        throw Exception('Unexpected server response: missing access token');
      }

      // Fetch full restaurant details for employees.
      if (isEmployee && _currentEmployee != null) {
        try {
          final restaurantService = RestaurantService();
          final fullRestaurant =
          await restaurantService.fetchFullRestaurantById(
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

      // Initialise FCM after a successful login.
      // Only customers receive push notifications; employees use the app
      // interactively and do not need a device token registered.
      if (isCustomer) {
        await _initFcm();
      }

      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_googleSignInInitialized) {
      await GoogleSignIn.instance.initialize(
        // Este es el Web Client ID que se usa como serverClientId para obtener el idToken
        serverClientId: '628423960645-kn89kchkb0adnspol23rm29qsae3mtpt.apps.googleusercontent.com',
        // Client ID de iOS
        clientId: '628423960645-ltdlujieph3vncdrfho9a544i2plucch.apps.googleusercontent.com',
      );
      _googleSignInInitialized = true;
    }
  }

  Future<bool> loginWithGoogle({String role = 'customer'}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      final Map<String, dynamic> response = await _authService.loginWithGoogle(
        idToken,
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
        final dynamic maybeUser = rawEmployee ?? rawUser;
        if (maybeUser is Map<String, dynamic>) {
          final empRest = maybeUser['restaurant'] ??
              maybeUser['restaurant_id'] ??
              maybeUser['restaurantId'];
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
      } else if (rawEmployee is Map<String, dynamic>) {
        _accountType = AuthAccountType.employee;
        _currentEmployee = Employee.fromJson(rawEmployee);
      } else if (rawAdmin is Map<String, dynamic>) {
        _accountType = AuthAccountType.employee;
        _currentEmployee = Employee.fromJson(rawAdmin);
      } else if (rawUser is Map<String, dynamic>) {
        if (role == 'customer') {
          _accountType = AuthAccountType.customer;
          _currentCustomer = Customer.fromJson(rawUser);
        } else {
          _accountType = AuthAccountType.employee;
          _currentEmployee = Employee.fromJson(rawUser);
        }
      } else {
        throw Exception(
            'Unexpected server response: missing customer/employee data');
      }

      if (_accessToken == null || _accessToken!.isEmpty) {
        throw Exception('Unexpected server response: missing access token');
      }

      // Fetch full restaurant details for employees.
      if (isEmployee && _currentEmployee != null) {
        try {
          final restaurantService = RestaurantService();
          final fullRestaurant =
          await restaurantService.fetchFullRestaurantById(
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

      if (isCustomer) {
        await _initFcm();
      }

      return true;
    } on GoogleSignInException catch (e) {
      _isLoading = false;
      if (e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted) {
        notifyListeners();
        return false;
      }
      _errorMessage = e.description ?? e.toString();
      notifyListeners();
      await GoogleSignIn.instance.signOut();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      await GoogleSignIn.instance.signOut();
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Sign-up
  // ──────────────────────────────────────────────────────────────────────────

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

  Future<bool> registerWithGoogle() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      await _authService.registerWithGoogle(idToken);
      
      // Login flow is embedded inside registerWithGoogle
      // To get the session we need to call loginWithGoogle. 
      // But we just did a register. Since Google already authorized us, we can safely call loginWithGoogle.
      
      final Map<String, dynamic> response = await _authService.loginWithGoogle(
        idToken,
        role: 'customer',
      );

      _accessToken = (response['accessToken'] ?? response['token'])?.toString();

      final dynamic rawCustomer = response['customer'] ?? response['user'] ?? response['usuario'];
      _accountType = AuthAccountType.customer;
      _currentCustomer = Customer.fromJson(rawCustomer);

      if (_accessToken == null || _accessToken!.isEmpty) {
        throw Exception('Unexpected server response: missing access token');
      }

      _isLoading = false;
      notifyListeners();

      if (isCustomer) {
        await _initFcm();
      }

      return true;
    } on GoogleSignInException catch (e) {
      _isLoading = false;
      if (e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted) {
        notifyListeners();
        return false;
      }
      _errorMessage = e.description ?? e.toString();
      notifyListeners();
      await GoogleSignIn.instance.signOut();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      await GoogleSignIn.instance.signOut();
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Logout
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    // Dispose FCM first so the backend knows this device is no longer active
    // and stops delivering notifications for the outgoing user.
    await _fcmService.dispose(accessToken: _accessToken);

    _resetSessionState();
    _errorMessage = '';

    await _authService.logout();
    await GoogleSignIn.instance.signOut();
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Profile helpers
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> loadProfileFromApi() async {
    if (id == null || _accessToken == null || _accessToken!.isEmpty) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (isCustomer) {
        final Map<String, dynamic> rawUser =
        await _authService.fetchCustomerById(id!, _accessToken!);
        final data = rawUser['data'] ?? rawUser;
        _currentCustomer = Customer.fromJson(data);
      } else if (isEmployee) {
        final Map<String, dynamic> rawUser =
        await _authService.fetchEmployeeById(id!, _accessToken!);
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
              if (phone != null && phone.trim().isNotEmpty)
                'phone': phone.trim(),
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

  // ──────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Fetches the full user profile (and restaurant for employees).
  /// Throws on failure so callers can handle retry logic.
  Future<void> _fetchUserProfile(
      String userId, String role, String token) async {
    if (role == 'customer') {
      _accountType = AuthAccountType.customer;
      final rawUser = await _authService.fetchCustomerById(userId, token);
      final data = rawUser['data'] ?? rawUser;
      _currentCustomer = Customer.fromJson(data);
    } else {
      _accountType = AuthAccountType.employee;
      final rawUser = await _authService.fetchEmployeeById(userId, token);
      final data = rawUser['data'] ?? rawUser;
      _currentEmployee = Employee.fromJson(data);

      if (_currentEmployee != null) {
        try {
          final restaurantService = RestaurantService();
          final fullRestaurant =
          await restaurantService.fetchFullRestaurantById(
            _currentEmployee!.restaurantId,
            accessToken: _accessToken,
          );
          _restaurant = fullRestaurant;
        } catch (e) {
          debugPrint('Error fetching restaurant during session restore: $e');
        }
      }
    }
  }

  /// Initialises FCM for the currently authenticated customer.
  ///
  /// Safe to call multiple times – [FcmService.initialize] is idempotent.
  Future<void> _initFcm() async {
    if (!isCustomer || id == null) return;

    try {
      await _fcmService.initialize(
        customerId: id,
        // Pass a getter callback so the token-refresh subscription always
        // reads the latest access token, not a stale captured value.
        getAccessToken: () => _accessToken,
        onNotificationTap: (payload) async {
          // Payload routing is handled by NotificationRouter in the UI layer.
          // We publish the event via notifyListeners so widgets can react.
          _lastNotificationPayload = payload;
          notifyListeners();
        },
        onForegroundNotification: (notification) {
          _lastForegroundNotification = notification;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('[AuthProvider] FCM initialisation error: $e');
      // Non-fatal – the app works without push notifications.
    }
  }

  void _resetSessionState() {
    _currentCustomer = null;
    _currentEmployee = null;
    _restaurant = null;
    _accessToken = null;
    _accountType = AuthAccountType.none;
    _lastNotificationPayload = null;
    _lastForegroundNotification = null;
  }

  // ── Notification event surface ─────────────────────────────────────────────
  //
  // Widgets (e.g. NotificationRouter) can listen to these via context.watch()
  // and act on incoming notifications without needing a separate stream.

  Map<String, dynamic>? _lastNotificationPayload;
  dynamic _lastForegroundNotification; // NotificationModel

  /// The most recent notification payload received while the app was in the
  /// foreground or opened from a tapped notification.  Consumed by the UI
  /// layer (e.g. NotificationRouter) and should be cleared after handling.
  Map<String, dynamic>? get lastNotificationPayload => _lastNotificationPayload;

  /// The most recent [NotificationModel] delivered in the foreground.
  dynamic get lastForegroundNotification => _lastForegroundNotification;

  /// Called by the UI after it has handled [lastNotificationPayload].
  void clearLastNotificationPayload() {
    _lastNotificationPayload = null;
    notifyListeners();
  }

  /// Called by the UI after it has handled [lastForegroundNotification].
  void clearLastForegroundNotification() {
    _lastForegroundNotification = null;
    notifyListeners();
  }
}