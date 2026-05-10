import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/customer.dart';
import '../models/customerStats.dart';

class CustomerService {
  final String baseUrl = '${AppConstants.baseUrl}/customers';

  Future<Map<String, String>> _headers(String? token) async {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Customer> createCustomer(Customer customer) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: await _headers(null),
      body: json.encode(customer.toJson()),
    );

    if (response.statusCode == 201) {
      return Customer.fromJson(json.decode(response.body));
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to create customer');
    }
  }

  Future<Customer> getCustomerById(String id, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(token),
    );

    if (response.statusCode == 200) {
      return Customer.fromJson(json.decode(response.body));
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to get customer');
    }
  }

  Future<Customer> updateCustomer(String id, Map<String, dynamic> data, String token) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: await _headers(token),
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return Customer.fromJson(json.decode(response.body));
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to update customer');
    }
  }

  Future<Map<String, dynamic>> getCustomerFull(String id, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id/full'),
      headers: await _headers(token),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to get full customer data');
    }
  }

  Future<Map<String, dynamic>> getCustomerBadges(String id, String token, {int page = 1, int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id/badges?page=$page&limit=$limit'),
      headers: await _headers(token),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to get badges');
    }
  }

  Future<Map<String, dynamic>> getCustomerFavouriteRestaurants(String id, String token, {int page = 1, int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id/favouriteRestaurants?page=$page&limit=$limit'),
      headers: await _headers(token),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to get favourite restaurants');
    }
  }

  Future<Map<String, dynamic>> getCustomerPointsWallet(String id, String token, {int page = 1, int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id/pointsWallet?page=$page&limit=$limit'),
      headers: await _headers(token),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to get points wallet');
    }
  }

  Future<Map<String, dynamic>> getCustomerReviews(String id, String token, {int page = 1, int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id/reviews?page=$page&limit=$limit'),
      headers: await _headers(token),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to get reviews');
    }
  }

  Future<Map<String, dynamic>> getCustomerVisits(String id, String token, {int page = 1, int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id/visits?page=$page&limit=$limit'),
      headers: await _headers(token),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to get visits');
    }
  }

  Future<void> softDeleteCustomer(String id, String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id/soft'),
      headers: await _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to soft delete customer');
    }
  }

  Future<void> restoreCustomer(String id, String token) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$id/restore'),
      headers: await _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to restore customer');
    }
  }

  Future<CustomerStatistics> fetchCustomerStatistics(
    String customerId, {
    String? accessToken,
  }) async {
    final uri = Uri.parse('$baseUrl/$customerId/statistics');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load customer statistics (${response.statusCode})',
      );
    }

    final dynamic body = json.decode(response.body);

    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return CustomerStatistics.fromJson(data);
      }
      return CustomerStatistics.fromJson(body);
    }

    throw Exception('Unexpected customer statistics response format');
  }
}
