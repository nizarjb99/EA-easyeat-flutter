// lib/services/location_service.dart
import 'dart:math';
import '../models/restaurant.dart';
import 'restaurant_service.dart';

class LocationService {
  final RestaurantService _restaurantService = RestaurantService();

  /// Get all restaurants (for Discover screen - no location needed)
  Future<List<Restaurant>> getAllRestaurants() async {
    return await _restaurantService.fetchRestaurants();
  }

  /// Get restaurants by category (for Discover screen - no location needed)
  Future<List<Restaurant>> getRestaurantsByCategory(String category) async {
    // You can enhance this if your API supports category filtering
    return await _restaurantService.fetchRestaurants();
  }

  /// Get featured restaurants (for Discover screen - no location needed)
  Future<List<Restaurant>> getFeaturedRestaurants() async {
    return await _restaurantService.fetchRestaurants();
  }

  /// Get restaurants within a city (for Map screen - no location needed)
  Future<List<Restaurant>> getRestaurantsByCity(String city) async {
    return await _restaurantService.fetchRestaurants();
  }

  /// Get nearby restaurants (ONLY after location permission granted)
  Future<List<Restaurant>> getNearbyRestaurants({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    final allRestaurants = await _restaurantService.fetchRestaurants();

    // Filter by proximity
    return allRestaurants.where((restaurant) {
      final coords = restaurant.profile.location.coordinates.coordinates;
      final distance = _calculateDistance(
        latitude,
        longitude,
        coords[1], // latitude
        coords[0], // longitude
      );
      return distance <= radiusKm;
    }).toList();
  }

  /// Calculate distance between two points in km (Haversine formula)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lng2 - lng1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}