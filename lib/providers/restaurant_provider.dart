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

    Future<void> loadNearbyRestaurants(
      double latitude,
      double longitude, {
      int maxDistanceMeters = 1000,
      String? accessToken,
    }) async {
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        // Call backend endpoint that returns nearby restaurants
        // Note: RestaurantService expects lng then lat
        _nearbyRestaurants = await _restaurantService.fetchRestaurantsNearBy(
          lng: longitude,
          lat: latitude,
          maxDistance: maxDistanceMeters,
        );

        _error = null;
      } catch (e) {
        _error = 'Failed to load nearby restaurants: $e';
        _nearbyRestaurants = [];
      }

      _isLoading = false;
      notifyListeners();
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