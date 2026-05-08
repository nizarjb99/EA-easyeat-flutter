// lib/providers/location_provider.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocationPermissionStatus {
  notRequested,
  requesting,
  granted,
  denied,
}

class LocationProvider extends ChangeNotifier {
  // State
  LocationPermissionStatus _permissionStatus = LocationPermissionStatus.notRequested;
  Position? _currentPosition;
  Map<String, double>? _lastSavedLocation; // {lat, lng}

  // Default location: Barcelona
  static const double DEFAULT_LAT = 41.3851;
  static const double DEFAULT_LNG = 2.1734;
  static const String DEFAULT_CITY = 'Barcelona';

  // Getters
  LocationPermissionStatus get permissionStatus => _permissionStatus;
  Position? get currentPosition => _currentPosition;

  /// Returns the location to display on map:
  /// 1. Current position (if granted)
  /// 2. Last saved location (if available)
  /// 3. Default location (Barcelona)
  Map<String, double> get mapCenterLocation {
    if (_currentPosition != null) {
      return {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
      };
    }
    if (_lastSavedLocation != null) {
      return _lastSavedLocation!;
    }
    return {
      'latitude': DEFAULT_LAT,
      'longitude': DEFAULT_LNG,
    };
  }

  /// Initialize: Load last saved location from cache
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLat = prefs.getDouble('saved_location_lat');
      final savedLng = prefs.getDouble('saved_location_lng');

      if (savedLat != null && savedLng != null) {
        _lastSavedLocation = {
          'latitude': savedLat,
          'longitude': savedLng,
        };
      }
      notifyListeners();
    } catch (e) {
      print('Error loading saved location: $e');
    }
  }

  /// ONLY call this when user explicitly clicks "See near me"
  Future<void> requestLocationPermission() async {
    _permissionStatus = LocationPermissionStatus.requesting;
    notifyListeners();

    try {
      final status = await Geolocator.checkPermission();

      if (status == LocationPermission.denied) {
        // Permission not requested yet - ask the user
        final permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          await _fetchAndSavePosition();
          _permissionStatus = LocationPermissionStatus.granted;
        } else {
          _permissionStatus = LocationPermissionStatus.denied;
        }
      } else if (status == LocationPermission.whileInUse ||
                 status == LocationPermission.always) {
        // Already granted
        await _fetchAndSavePosition();
        _permissionStatus = LocationPermissionStatus.granted;
      } else if (status == LocationPermission.deniedForever) {
        // Permission denied permanently
        _permissionStatus = LocationPermissionStatus.denied;
        // Show dialog suggesting to open settings
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      print('Error requesting location permission: $e');
      _permissionStatus = LocationPermissionStatus.denied;
    }

    notifyListeners();
  }

  /// Fetch current position and save it
  Future<void> _fetchAndSavePosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;

      // Save to cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('saved_location_lat', position.latitude);
      await prefs.setDouble('saved_location_lng', position.longitude);

      _lastSavedLocation = {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

      notifyListeners();
    } catch (e) {
      print('Error fetching position: $e');
    }
  }

  void _showPermissionDeniedDialog() {
    // This will be called from the UI
    print('Location permission denied permanently. Show settings dialog.');
  }

  /// Calculate distance between two points (for filtering nearby restaurants)
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lng2 - lng1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Reset to initial state (for logout)
  void reset() {
    _permissionStatus = LocationPermissionStatus.notRequested;
    _currentPosition = null;
    notifyListeners();
  }
}