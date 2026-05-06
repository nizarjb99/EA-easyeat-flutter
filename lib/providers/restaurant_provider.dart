// lib/providers/restaurant_provider.dart
import 'dart:math';

import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/location_service.dart';
import '../services/restaurant_service.dart';


class RestaurantProvider extends ChangeNotifier {
  final RestaurantService _restaurantService = RestaurantService();

  List<Restaurant> _allRestaurants = [];
  List<Restaurant> _featuredRestaurants = [];
  List<Restaurant> _nearbyRestaurants = [];
  List<Restaurant> _categorizedRestaurants = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  List<Restaurant> get allRestaurants => _allRestaurants;
  List<Restaurant> get featuredRestaurants => _featuredRestaurants;
  List<Restaurant> get nearbyRestaurants => _nearbyRestaurants;
  List<Restaurant> get categorizedRestaurants => _categorizedRestaurants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all restaurants (for Discover screen)
  /// ❌ NO LOCATION NEEDED
  Future<void> loadAllRestaurants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allRestaurants = await _restaurantService.fetchRestaurants();
      _error = null;
    } catch (e) {
      _error = 'Failed to load restaurants: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load featured restaurants (for Discover screen)
  /// ❌ NO LOCATION NEEDED
  Future<void> loadFeaturedRestaurants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Using the existing fetchRestaurants as featured
      _featuredRestaurants = await _restaurantService.fetchRestaurants();
      _error = null;
    } catch (e) {
      _error = 'Failed to load featured restaurants: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load restaurants by category (for Discover screen)
  /// ❌ NO LOCATION NEEDED
  Future<void> loadRestaurantsByCategory(String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categorizedRestaurants = await _restaurantService.fetchRestaurants();
      _error = null;
    } catch (e) {
      _error = 'Failed to load restaurants: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load nearby restaurants (ONLY after location permission granted)
  /// ✅ LOCATION REQUIRED
  Future<void> loadNearbyRestaurants(double latitude, double longitude) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch all restaurants and filter by proximity
      final allRestaurants = await _restaurantService.fetchRestaurants();

      // Filter restaurants within 5km radius
      _nearbyRestaurants = allRestaurants.where((restaurant) {
        final coords = restaurant.profile.location.coordinates.coordinates;
        final distance = _calculateDistance(
          latitude,
          longitude,
          coords[1], // latitude
          coords[0], // longitude
        );
        return distance <= 5.0; // 5km radius
      }).toList();

      _error = null;
    } catch (e) {
      _error = 'Failed to load nearby restaurants: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Calculate distance between two points in km (Haversine formula)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lng2 - lng1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  void clearNearbyRestaurants() {
    _nearbyRestaurants = [];
    notifyListeners();
  }

  void reset() {
    _allRestaurants = [];
    _featuredRestaurants = [];
    _nearbyRestaurants = [];
    _categorizedRestaurants = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}