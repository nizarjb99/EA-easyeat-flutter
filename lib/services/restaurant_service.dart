import 'dart:convert';

import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/restaurant.dart';
import '../models/visit.dart';

class RestaurantService {
  final String _baseUrl = '${AppConstants.baseUrl}/restaurants';

  Future<List<Restaurant>> fetchRestaurants({int page = 1, int limit = 10}) async {
    final uri = Uri.parse('$_baseUrl?page=$page&limit=$limit');
    final response = await http.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load restaurants (${response.statusCode})');
    }

    final dynamic body = json.decode(response.body);
    final List<dynamic> list = _extractList(body);

    return list
        .whereType<Map<String, dynamic>>()
        .map(Restaurant.fromJson)
        .toList();
  }

  Future<Restaurant> fetchRestaurantById(String restaurantId, {String? accessToken}) async {
    final uri = Uri.parse('$_baseUrl/$restaurantId');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load restaurant (${response.statusCode})');
    }

    final dynamic body = json.decode(response.body);

    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return Restaurant.fromJson(data);
      return Restaurant.fromJson(body);
    }

    throw Exception('Unexpected restaurant response format');
  }

  Future<List<Visit>> fetchVisitsByRestaurant(String restaurantId, { String? accessToken, int page = 1, int limit = 10 }) async {
    // If your backend route differs, only change this path.
    final uri = Uri.parse(
      '$_baseUrl/$restaurantId/visits?page=$page&limit=$limit',
    );

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load visits (${response.statusCode})');
    }

    final dynamic body = json.decode(response.body);
    final List<dynamic> list = _extractList(body);

    return list
        .whereType<Map<String, dynamic>>()
        .map(Visit.fromJson)
        .toList();
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List<dynamic>) return body;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List<dynamic>) return data;

      final items = body['items'];
      if (items is List<dynamic>) return items;

      final results = body['results'];
      if (results is List<dynamic>) return results;
    }
    return const <dynamic>[];
  }
}
