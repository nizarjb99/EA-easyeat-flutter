import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  // ─── SharedPreferences keys ────────────────────────────────────────────────
  static const String _keyAccessToken = 'accessToken';
  static const String _keyUserId = 'userId';
  static const String _keyUserRole = 'userRole';

  // ──────────────────────────────────────────────────────────────────────────
  // Login
  // ──────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(
      String email,
      String password, {
        String role = 'employee',
      }) async {
    late http.Response response;

    try {
      response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'role': role,
        }),
      );
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }

    if (response.statusCode != 200) {
      final body = _tryDecode(response.body);
      throw Exception(body?['message'] ?? 'Authentication error');
    }

    final Map<String, dynamic> responseBody =
    json.decode(response.body) as Map<String, dynamic>;

    // ── Persist the session ──────────────────────────────────────────────────
    //
    // The backend may return the user id as a top-level 'userId' field, or
    // nested inside the customer/employee object as '_id' or 'id'.
    // We try all common locations so the persisted value is never null.
    final token =
    (responseBody['accessToken'] ?? responseBody['token'])?.toString();

    final rawUser = responseBody['customer'] ??
        responseBody['employee'] ??
        responseBody['admin'] ??
        responseBody['user'] ??
        responseBody['usuario'];

    String? userId;
    if (responseBody['userId'] != null) {
      userId = responseBody['userId'].toString();
    } else if (rawUser is Map<String, dynamic>) {
      userId = (rawUser['_id'] ?? rawUser['id'])?.toString();
    }

    if (token == null || token.isEmpty) {
      throw Exception('Unexpected server response: missing access token');
    }
    if (userId == null || userId.isEmpty) {
      throw Exception('Unexpected server response: missing user id');
    }

    await _persistSession(token: token, userId: userId, role: role);

    return responseBody;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Logout
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserRole);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Session accessors
  // ──────────────────────────────────────────────────────────────────────────

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Token refresh
  // ──────────────────────────────────────────────────────────────────────────

  /// Calls POST /auth/refresh with the current access token to obtain a new
  /// one. Persists and returns the new token on success, or `null` on failure.
  Future<String?> refreshToken(String currentToken) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/refresh'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $currentToken',
        },
      );

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final newToken = (body['accessToken'] ?? body['token'])?.toString();

        if (newToken != null && newToken.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyAccessToken, newToken);
          return newToken;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Sign-up
  // ──────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> signup(
      String name,
      String email,
      String password,
      ) async {
    late http.Response response;
    try {
      response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/customers'),
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }

    if (response.statusCode == 201) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    final body = _tryDecode(response.body);
    throw Exception(body?['message'] ?? 'Error registering user');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // User-profile fetchers
  // ──────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchCustomerById(
      String customerId,
      String accessToken,
      ) async {
    late http.Response response;
    try {
      response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/customers/$customerId'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    final body = _tryDecode(response.body);
    throw Exception(body?['message'] ?? 'Error getting customer');
  }

  Future<Map<String, dynamic>> fetchEmployeeById(
      String employeeId,
      String accessToken,
      ) async {
    late http.Response response;
    try {
      response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/employees/$employeeId'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    final body = _tryDecode(response.body);
    throw Exception(body?['message'] ?? 'Error getting employee');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _persistSession({
    required String token,
    required String userId,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, token);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyUserRole, role);
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}