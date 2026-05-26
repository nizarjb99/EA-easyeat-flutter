import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ea_easyeat_flutter/models/restaurant.dart';
import 'package:ea_easyeat_flutter/screens/_common/restaurant_card.dart';
import 'package:ea_easyeat_flutter/screens/_common/restaurant_detail_screen.dart';

import '../../providers/location_provider.dart';
import '../../providers/restaurant_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _showNearby = false;

  // New state for marker -> card interaction
  Restaurant? _selectedRestaurant;
  bool _cardVisible = false;

  @override
  void initState() {
    super.initState();
    // Load all restaurants when map screen opens (if not already loaded)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurantProvider = context.read<RestaurantProvider>();
      if (restaurantProvider.allRestaurants.isEmpty) {
        restaurantProvider.loadAllRestaurants();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ Map'),
        elevation: 0,
      ),
      body: Consumer2<LocationProvider, RestaurantProvider>(
        builder: (context, locationProvider, restaurantProvider, _) {
          final mapCenter = locationProvider.mapCenterLocation;

          return Stack(
            children: [
              // Google Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    mapCenter['latitude']!,
                    mapCenter['longitude']!,
                  ),
                  zoom: 14,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                markers: _buildMarkers(restaurantProvider, locationProvider),
                myLocationEnabled: locationProvider.permissionStatus ==
                    LocationPermissionStatus.granted,
                myLocationButtonEnabled: false,
                // Dismiss restaurant card when user taps on map
                onTap: (_) {
                  if (_cardVisible) {
                    setState(() {
                      _cardVisible = false;
                      _selectedRestaurant = null;
                    });
                  }
                },
              ),

              // Floating Action Button: "See Near Me"
              Positioned(
                bottom: 30,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => _handleSeeNearMe(
                      context, locationProvider, restaurantProvider),
                  backgroundColor: const Color(0xFFFF7A1A),
                  label: const Text('📍 See Near Me'),
                  icon: const Icon(Icons.location_on),
                ),
              ),

              // Loading Overlay
              if (restaurantProvider.isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),

              // Restaurant card overlay (bottom)
              if (_cardVisible && _selectedRestaurant != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 110, // above the FAB
                  child: _buildRestaurantCardOverlay(
                    _selectedRestaurant!,
                    locationProvider,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRestaurantCardOverlay(
      Restaurant restaurant, LocationProvider locationProvider) {
    final distance = _formatDistance(restaurant, locationProvider);

    return RestaurantCard(
      restaurant: restaurant,
      distance: distance,
      hasSpecialOffer: false,
      onClick: () {
        // Hide the overlay and navigate to detail
        setState(() {
          _cardVisible = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RestaurantDetailScreen(restaurant: restaurant),
          ),
        );
      },
    );
  }

  String _formatDistance(
      Restaurant restaurant, LocationProvider locationProvider) {
    final coords = restaurant.profile.location.coordinates.coordinates;
    if (coords.length != 2) return "-- km";

    if (locationProvider.currentPosition == null) {
      return "-- km";
    }

    try {
      final km = locationProvider.calculateDistance(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
        coords[1], // latitude
        coords[0], // longitude
      );
      return "${km.toStringAsFixed(1)} km";
    } catch (_) {
      return "-- km";
    }
  }

  void _handleSeeNearMe(
    BuildContext context,
    LocationProvider locationProvider,
    RestaurantProvider restaurantProvider,
  ) async {
    // If permission already granted, just load nearby restaurants
    if (locationProvider.permissionStatus ==
            LocationPermissionStatus.granted &&
        locationProvider.currentPosition != null) {
      await restaurantProvider.loadNearbyRestaurants(
        locationProvider.currentPosition!.latitude,
        locationProvider.currentPosition!.longitude,
      );
      setState(() => _showNearby = true);
      _animateToUserLocation(locationProvider);
      return;
    }

    // Request permission first
    if (locationProvider.permissionStatus ==
        LocationPermissionStatus.notRequested) {
      await locationProvider.requestLocationPermission();

      if (locationProvider.permissionStatus ==
              LocationPermissionStatus.granted &&
          locationProvider.currentPosition != null) {
        // Permission granted, load nearby restaurants
        await restaurantProvider.loadNearbyRestaurants(
          locationProvider.currentPosition!.latitude,
          locationProvider.currentPosition!.longitude,
        );
        setState(() => _showNearby = true);
        _animateToUserLocation(locationProvider);
      } else {
        // Permission denied
        if (!mounted) return;
        _showPermissionDeniedDialog(context);
      }
    } else if (locationProvider.permissionStatus ==
        LocationPermissionStatus.denied) {
      // Previously denied
      _showPermissionDeniedDialog(context);
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text(
          'You can still browse restaurants manually on the map. To see nearby restaurants, enable location in your phone settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _animateToUserLocation(LocationProvider locationProvider) {
    if (locationProvider.currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          ),
        ),
      );
    }
  }

  Set<Marker> _buildMarkers(
    RestaurantProvider restaurantProvider,
    LocationProvider locationProvider,
  ) {
    Set<Marker> markers = {};

    // Add user location marker (if available)
    if (locationProvider.currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            locationProvider.currentPosition!.latitude,
            locationProvider.currentPosition!.longitude,
          ),
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
      );
    }

    // Add restaurant markers - show all by default, or nearby if user clicked "See Near Me"
    final restaurantsToShow = _showNearby
        ? restaurantProvider.nearbyRestaurants
        : restaurantProvider.allRestaurants;

    for (final restaurant in restaurantsToShow) {
      final coords = restaurant.profile.location.coordinates.coordinates;

      // Validate coordinates
      if (coords.length != 2) continue;

      markers.add(
        Marker(
          markerId: MarkerId(restaurant.id),
          position: LatLng(coords[1], coords[0]), // [lng, lat] -> LatLng(lat, lng)
          infoWindow: InfoWindow(title: restaurant.profile.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _showNearby ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
          ),
          onTap: () {
            // Show the RestaurantCard overlay for this restaurant
            setState(() {
              _selectedRestaurant = restaurant;
              _cardVisible = true;
            });
          },
        ),
      );
    }

    return markers;
  }

  @override
  void dispose() {
    // map controller is initialized on onMapCreated; keep same dispose as before.
    _mapController?.dispose();
    super.dispose();
  }
}