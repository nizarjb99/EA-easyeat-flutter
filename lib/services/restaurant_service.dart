import 'dart:convert';

import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/restaurant.dart';
import '../models/reward.dart';
import '../models/visit.dart';
import '../models/dish.dart';

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

  Future<List<Restaurant>> fetchRestaurantsNearBy({required double lng, required double lat, int maxDistance = 1000, // meters
  }) async {
    final uri = Uri.parse('$_baseUrl/near-by?lng=$lng&lat=$lat&maxDistance=$maxDistance');

    final response = await http.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load nearby restaurants (${response.statusCode})');
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

    final response = await http.get(uri);

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

  Future<Map<String, dynamic>> fetchFullRestaurantById(String restaurantId, {String? accessToken}) async {
    final uri = Uri.parse('$_baseUrl/$restaurantId/full');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(uri, headers: headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load full restaurant (${response.statusCode})');
    }

    final dynamic body = json.decode(response.body);

    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      return body;
    }

    throw Exception('Unexpected full restaurant response format');
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

  Future<List<Reward>> getRestaurantRewards(
    String restaurantId, {
    String? accessToken,
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse('$_baseUrl/$restaurantId/rewards?page=$page&limit=$limit');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to load rewards (${response.statusCode})');
      }

      final dynamic body = json.decode(response.body);
      final List<dynamic> list = _extractList(body);

      final rewards = list
          .whereType<Map<String, dynamic>>()
          .map(Reward.fromJson)
          .toList();

      // Filter: only return active rewards that haven't expired
      return rewards.where((reward) => reward.isValid).toList();
    } catch (e) {
      throw Exception('Error loading rewards: $e');
    }
  }

  /// Fetch dishes for a specific restaurant
  Future<List<Dish>> fetchDishesByRestaurant(
    String restaurantId, {
    String? accessToken,
    int page = 1,
    int limit = 20,
    String? section,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (section != null) 'section': section,
    };

    final uri = Uri.parse('$_baseUrl/$restaurantId/dishes')
        .replace(queryParameters: queryParams);

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to load dishes (${response.statusCode})');
      }

      final dynamic body = json.decode(response.body);
      final List<dynamic> list = _extractList(body);

      return list
          .whereType<Map<String, dynamic>>()
          .map(Dish.fromJson)
          .toList();
    } catch (e) {
      throw Exception('Error loading dishes: $e');
    }
  }

  /// Fetch a specific dish by ID
  Future<Dish> fetchDishById(
    String dishId, {
    String? accessToken,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/dishes/$dishId');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to load dish (${response.statusCode})');
      }

      final dynamic body = json.decode(response.body);

      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic>) return Dish.fromJson(data);
        return Dish.fromJson(body);
      }

      throw Exception('Unexpected dish response format');
    } catch (e) {
      throw Exception('Error loading dish: $e');
    }
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
