import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password, {String role = 'employee'}) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'role': role, 
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        
        // Assuming the response contains 'token', 'userId', and 'role'
        await prefs.setString('accessToken', responseBody['accessToken']);
        await prefs.setString('userId', responseBody['userId']);
        await prefs.setString('userRole', role); // Save the role used for login

        return responseBody;
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'Authentication error');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }
  }

  Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('userId');
    await prefs.remove('userRole');
    // Optionally, clear any other user-specific data
  }

  Future<String?> getAccessToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  Future<String?> getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  Future<String?> getUserRole() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole');
  }

  /// Calls POST /auth/refresh with the current access token to obtain a new one.
  /// Returns the new access token on success, or `null` on failure.
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
        final Map<String, dynamic> body = json.decode(response.body);
        final newToken = (body['accessToken'] ?? body['token'])?.toString();

        if (newToken != null && newToken.isNotEmpty) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', newToken);
          return newToken;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Create the customer using the existing backend endpoint
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/customers'),
        headers: <String, String>{'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'Error registering user');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }
  }


  Future<Map<String, dynamic>> fetchCustomerById(
    String customerId,
    String accessToken,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/customers/$customerId'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'Error getting customer');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }
  }

  Future<Map<String, dynamic>> fetchEmployeeById(
    String employeeId,
    String accessToken,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/employees/$employeeId'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final body = json.decode(response.body);
        throw Exception(body['message'] ?? 'Error getting employee');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }
  }
}
