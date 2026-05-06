// lib/screens/_common/map_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/location_provider.dart';
import '../../providers/restaurant_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  bool _showNearby = false;

  @override
  void initState() {
    super.initState();
    // Load all restaurants when map screen opens
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
              ),

              // Floating Action Button: "See Near Me"
              Positioned(
                bottom: 30,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: () => _handleSeeNearMe(context, locationProvider, restaurantProvider),
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
            ],
          );
        },
      ),
    );
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
    if (locationProvider.currentPosition != null) {
      _mapController.animateCamera(
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
        ),
      );
    }

    return markers;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}