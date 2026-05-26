import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ea_easyeat_flutter/models/restaurant.dart';

class MiniRestaurantMap extends StatefulWidget {
  final Restaurant restaurant;
  final double height;

  const MiniRestaurantMap({
    super.key,
    required this.restaurant,
    this.height = 250,
  });

  @override
  State<MiniRestaurantMap> createState() => _MiniRestaurantMapState();
}

class _MiniRestaurantMapState extends State<MiniRestaurantMap> {
  GoogleMapController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coords = widget.restaurant.profile.location.coordinates.coordinates;

    if (coords.length != 2) {
      return Container(
        height: widget.height,
        color: Colors.grey[200],
        child: const Center(
          child: Text('Ubicación no disponible'),
        ),
      );
    }

    final position = LatLng(coords[1], coords[0]); // [lat, lng]

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: GoogleMap(
        onMapCreated: (controller) => _controller = controller,
        initialCameraPosition: CameraPosition(
          target: position,
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('restaurant'),
            position: position,
            infoWindow: InfoWindow(
              title: widget.restaurant.profile.name,
              snippet: widget.restaurant.profile.location.address,
            ),
          ),
        },
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
      ),
    );
  }
}