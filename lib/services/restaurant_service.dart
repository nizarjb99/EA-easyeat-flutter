import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import '../models/visit.dart';
import '../utils/constants.dart';

class RestaurantService {
  Future<List<Restaurant>> getRestaurants() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/restaurants'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Restaurant.fromJson(json)).toList();
      } else {
        throw Exception('Error loading restaurants');
      }
    } catch (e) {
      throw Exception('Error connecting to the server: $e');
    }
  }

  Future<List<Visit>> fetchVisitsByRestaurant(String restaurantId, {String? accessToken}) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/visits/restaurant/$restaurantId'),
        headers: {
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Visit.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}
