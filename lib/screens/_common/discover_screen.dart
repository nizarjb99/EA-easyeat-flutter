import 'package:flutter/material.dart';
import 'package:ea_easyeat_flutter/models/restaurant.dart';
import 'package:ea_easyeat_flutter/screens/_common/restaurant_card.dart';
import 'package:ea_easyeat_flutter/services/restaurant_service.dart';
import 'package:ea_easyeat_flutter/screens/_common/restaurant_detail_screen.dart';

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
  String _searchQuery = '';
  String? _selectedCity;
  String? _selectedCategory;
  List<Restaurant> _filteredRestaurants = [];
  Set<String> _availableCities = {};
  Set<String> _availableCategories = {};

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  void _filterRestaurants() {
    setState(() {
      _filteredRestaurants = _restaurants.where((restaurant) {
        final matchesName = restaurant.profile.name
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        final matchesCity = _selectedCity == null ||
            restaurant.profile.location.city == _selectedCity;
        final matchesCategory = _selectedCategory == null ||
            restaurant.profile.category.contains(_selectedCategory);

        return matchesName && matchesCity && matchesCategory;
      }).toList();
    });
  }

  Future<void> _fetchRestaurants() async {
    try {
      final restaurants = await _restaurantService.fetchRestaurants();
      setState(() {
        _restaurants = restaurants;
        _isLoading = false;

        _availableCities = _restaurants
            .map((r) => r.profile.location.city)
            .toSet();
        _availableCategories = _restaurants
            .fold<Set<String>>({}, (set, r) => set..addAll(r.profile.category));
        _filterRestaurants();
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
              : Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterRestaurants();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by restaurant name...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                    // Filter Dropdowns Row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            // City Filter
                            DropdownButton<String?>(
                              value: _selectedCity,
                              hint: const Text('All Cities'),
                              onChanged: (value) {
                                setState(() => _selectedCity = value);
                                _filterRestaurants();
                              },
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All Cities'),
                                ),
                                ..._availableCities.map((city) =>
                                    DropdownMenuItem(
                                      value: city,
                                      child: Text(city),
                                    )),
                              ],
                            ),
                            const SizedBox(width: 8),
                            // Category Filter
                            DropdownButton<String?>(
                              value: _selectedCategory,
                              hint: const Text('All Categories'),
                              onChanged: (value) {
                                setState(() => _selectedCategory = value);
                                _filterRestaurants();
                              },
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All Categories'),
                                ),
                                ..._availableCategories.map((category) =>
                                    DropdownMenuItem(
                                      value: category,
                                      child: Text(category),
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Results ListView
                    Expanded(
                      child: _filteredRestaurants.isEmpty
                          ? const Center(
                              child: Text('No restaurants match your search.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: _filteredRestaurants.length,
                              itemBuilder: (context, index) {
                                final restaurant = _filteredRestaurants[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: RestaurantCard(
                                    restaurant: restaurant,
                                    distance: "2.5 km",
                                    pointsMultiplier: 2,
                                    hasSpecialOffer: index % 3 == 0,
                                    onClick: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RestaurantDetailScreen(
                                                  restaurant: restaurant),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}