import 'package:flutter/material.dart';
import 'package:ea_easyeat_flutter/models/restaurant.dart';
import 'package:ea_easyeat_flutter/screens/restaurant_card.dart';
import 'package:ea_easyeat_flutter/services/restaurant_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  List<Restaurant> _restaurants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  Future<void> _fetchRestaurants() async {
    try {
      final restaurants = await _restaurantService.fetchRestaurants();
      setState(() {
        _restaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load restaurants: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _restaurants.isEmpty
                  ? const Center(child: Text('No restaurants found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _restaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = _restaurants[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: RestaurantCard(
                            restaurant: restaurant,
                            distance: "2.5 km", // Still mock distance
                            pointsMultiplier: 2, // Still mock multiplier
                            hasSpecialOffer: index % 3 == 0, // Still mock logic
                            onClick: () {
                              // Handle card click
                              print('Restaurant ${restaurant.profile.name} clicked!');
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}