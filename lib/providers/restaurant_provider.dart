// lib/providers/restaurant_provider.dart
import 'dart:math';

import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/location_service.dart';
import '../services/restaurant_service.dart';


class RestaurantProvider extends ChangeNotifier {
  final RestaurantService _restaurantService = RestaurantService();

  // Cache for rewards per restaurant
  final Map<String, List<dynamic>> _rewardsByRestaurant = {};
  final Map<String, String?> _rewardsErrorByRestaurant = {};
  final Map<String, bool> _rewardsLoading = {};

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

  // ---------------------------------------------------------------------
  // Rewards handling (per restaurant)
  // ---------------------------------------------------------------------
  /// Returns cached rewards for [restaurantId] or an empty list if none loaded yet.
  List getRewards(String restaurantId) => _rewardsByRestaurant[restaurantId] ?? [];

  String? getRewardsError(String restaurantId) => _rewardsErrorByRestaurant[restaurantId];

  bool isRewardsLoading(String restaurantId) => _rewardsLoading[restaurantId] ?? false;

  /// Loads rewards for a single restaurant and caches them.
  Future<void> loadRewardsFor(String restaurantId) async {
    // Avoid duplicate concurrent loads
    if (isRewardsLoading(restaurantId)) return;
    _rewardsLoading[restaurantId] = true;
    _rewardsErrorByRestaurant[restaurantId] = null;
    notifyListeners();

    try {
      final rewards = await _restaurantService.getRestaurantRewards(restaurantId);
      _rewardsByRestaurant[restaurantId] = rewards;
      _rewardsErrorByRestaurant[restaurantId] = null;
    } catch (e) {
      _rewardsByRestaurant[restaurantId] = [];
      _rewardsErrorByRestaurant[restaurantId] = 'Failed to load rewards: $e';
    }

    _rewardsLoading[restaurantId] = false;
    notifyListeners();
  }

  /// Simple prefetch for a list of restaurant ids. Runs loads in parallel.
  Future<void> prefetchRewardsFor(List<String> restaurantIds) async {
    final futures = <Future<void>>[];
    for (final id in restaurantIds) {
      // Skip if already loaded
      if (_rewardsByRestaurant.containsKey(id)) continue;
      futures.add(loadRewardsFor(id));
    }
    await Future.wait(futures);
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