import 'package:flutter/material.dart';
import 'package:ea_easyeat_flutter/models/restaurant.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ea_easyeat_flutter/screens/_common/restaurant_card.dart';
import 'package:ea_easyeat_flutter/services/restaurant_service.dart';
import 'package:ea_easyeat_flutter/screens/_common/restaurant_detail_screen.dart';
import 'package:ea_easyeat_flutter/screens/_common/map_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ea_easyeat_flutter/screens/_common/popup_assistant_screen.dart';
import '../../widgets/language_dropdown_widget.dart';

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
  Position? _userLocation;

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
  }

  void _filterRestaurants() {
    setState(() {
      _filteredRestaurants = _restaurants.where((restaurant) {
        final matchesName = restaurant.profile.name.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        final matchesCity =
            _selectedCity == null ||
            restaurant.profile.location.city == _selectedCity;
        final matchesCategory =
            _selectedCategory == null ||
            restaurant.profile.category.contains(_selectedCategory);

        return matchesName && matchesCity && matchesCategory;
      }).toList();
    });
  }

  String _calculateDistance(Restaurant restaurant) {
    if (_userLocation == null) return "-- km";
    final coords = restaurant.profile.location.coordinates.coordinates;
    final distance = Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      restaurant.profile.location.coordinates.coordinates[1],
      restaurant.profile.location.coordinates.coordinates[0],
    );
    return "${(distance / 1000).toStringAsFixed(1)} km";
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
        _availableCategories = _restaurants.fold<Set<String>>(
          {},
          (set, r) => set..addAll(r.profile.category),
        );
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
        title: Text('discover.title'.tr()),
        centerTitle: true,
        actions: [
          LanguageDropdownWidget(),
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'discover.open_map'.tr(),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MapScreen()),
              );
            },
          ),
        ],
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
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            _searchQuery = value;
                            _filterRestaurants();
                          },
                          decoration: InputDecoration(
                            hintText: 'discover.search_by_name'.tr(),
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE9D9),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: const Color(0xFFFF7A1A).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.smart_toy_rounded,
                            color: Color(0xFFFF7A1A),
                            size: 28,
                          ),
                          tooltip: 'assistant.title'.tr(),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const PopupAssistantScreen(),
                            );
                          },
                        ),
                      ),
                    ],
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
                          hint: Text('discover.all_cities'.tr()),
                          onChanged: (value) {
                            setState(() => _selectedCity = value);
                            _filterRestaurants();
                          },
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text('discover.all_cities'.tr()),
                            ),
                            ..._availableCities.map(
                              (city) => DropdownMenuItem(
                                value: city,
                                child: Text(city),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Category Filter
                        DropdownButton<String?>(
                          value: _selectedCategory,
                          hint: Text('discover.all_categories'.tr()),
                          onChanged: (value) {
                            setState(() => _selectedCategory = value);
                            _filterRestaurants();
                          },
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text('discover.all_categories'.tr()),
                            ),
                            ..._availableCategories.map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Results ListView
                Expanded(
                  child: _filteredRestaurants.isEmpty
                      ? Center(child: Text('discover.no_results'.tr()))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredRestaurants.length,
                          itemBuilder: (context, index) {
                            final restaurant = _filteredRestaurants[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: RestaurantCard(
                                restaurant: restaurant,
                                distance: _calculateDistance(restaurant),
                                onClick: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          RestaurantDetailScreen(
                                            restaurant: restaurant,
                                          ),
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
