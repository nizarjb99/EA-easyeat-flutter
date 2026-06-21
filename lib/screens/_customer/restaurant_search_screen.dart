import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';
import '../../providers/location_provider.dart';
import '../_common/restaurant_card.dart';
import '../_common/restaurant_detail_screen.dart';
import '../../utils/styles.dart';
import '../_common/accessibility/accessibility_controller.dart';

// Color Palette matching design systems
const Color _orange = Color(0xFFFF7A1A);
const Color _orangeLight = Color(0xFFFFF0EA);
const Color _dark = Color(0xFF0F172A);
const Color _grey = Color(0xFF64748B);

class RestaurantSearchScreen extends StatefulWidget {
  const RestaurantSearchScreen({super.key});

  @override
  State<RestaurantSearchScreen> createState() => _RestaurantSearchScreenState();
}

class _RestaurantSearchScreenState extends State<RestaurantSearchScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  final TextEditingController _searchController = TextEditingController();

  List<Restaurant> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  double _minRating = 0.0;

  @override
  void initState() {
    super.initState();
    // Perform an initial empty search to load restaurants
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _restaurantService.searchRestaurants(
        term: _searchController.text,
        minRating: _minRating > 0 ? _minRating : null,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
          _hasSearched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
          _hasSearched = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('customer.error_loading_restaurants'.tr())),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _minRating = 0.0;
    });
    _performSearch();
  }

  String _tr(String key, String fallback) {
    final val = key.tr();
    return val == key ? fallback : val;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.dashboardBg : const Color(0xFFFFFBF7);
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final textColor = isDark ? AppColors.text : _dark;
    final mutedColor = isDark ? AppColors.textMuted : _grey;
    final a11y = context.watch<AccessibilityController>();
    final locationProvider = context.watch<LocationProvider>();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _tr('customer.search_title', 'Cercar Restaurants'),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            fontFamily: a11y.fontFamilyName,
            letterSpacing: a11y.letterSpacing,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty || _minRating > 0)
            TextButton(
              onPressed: _clearFilters,
              child: Text(
                'Netejar',
                style: TextStyle(
                  color: _orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: a11y.fontFamilyName,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isDark
                      ? []
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: TextField(
                  key: const Key('search_input_field'),
                  controller: _searchController,
                  style: TextStyle(color: textColor, fontFamily: a11y.fontFamilyName),
                  decoration: InputDecoration(
                    hintText: _tr('customer.search_hint', 'Cerca per nom, cuina, ciutat...'),
                    hintStyle: TextStyle(color: mutedColor),
                    prefixIcon: Icon(Icons.search_rounded, color: _orange),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: mutedColor),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
            ),

            // Rating Filter Slider Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'Valoració Mínima',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: a11y.fontFamilyName,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _minRating == 0.0 ? 'Totes' : '${_minRating.toStringAsFixed(1)} / 10',
                          style: TextStyle(
                            color: _orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: a11y.fontFamilyName,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _orange,
                        inactiveTrackColor: isDark ? Colors.grey[800] : Colors.grey[200],
                        thumbColor: _orange,
                        overlayColor: _orange.withOpacity(0.2),
                        valueIndicatorColor: _orange,
                        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                      ),
                      child: Slider(
                        key: const Key('rating_filter_slider'),
                        value: _minRating,
                        min: 0.0,
                        max: 10.0,
                        divisions: 20,
                        label: _minRating.toStringAsFixed(1),
                        onChanged: (val) {
                          setState(() {
                            _minRating = val;
                          });
                        },
                        onChangeEnd: (val) {
                          _performSearch();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Results Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_orange),
                      ),
                    )
                  : _searchResults.isEmpty
                      ? _buildEmptyState(textColor, mutedColor, a11y)
                      : ListView.builder(
                          key: const Key('search_results_list'),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final restaurant = _searchResults[index];

                            // Distance Calculation
                            String distanceStr = restaurant.profile.location.city;
                            final currentPos = locationProvider.currentPosition;
                            if (currentPos != null) {
                              final coords = restaurant.profile.location.coordinates.coordinates;
                              if (coords.length == 2) {
                                final km = locationProvider.calculateDistance(
                                  currentPos.latitude,
                                  currentPos.longitude,
                                  coords[1], // Latitude
                                  coords[0], // Longitude
                                );
                                distanceStr = '${km.toStringAsFixed(1)} km';
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: RestaurantCard(
                                restaurant: restaurant,
                                distance: distanceStr,
                                onClick: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
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
      ),
    );
  }

  Widget _buildEmptyState(Color textColor, Color mutedColor, AccessibilityController a11y) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 80,
                color: _orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _tr('customer.no_restaurants', 'No s\'ha trobat cap restaurant'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: textColor,
                fontFamily: a11y.fontFamilyName,
                letterSpacing: a11y.letterSpacing,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta cercar una altra cosa o neteja els filtres seleccionats.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: mutedColor,
                fontFamily: a11y.fontFamilyName,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Netejar filtres',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: a11y.fontFamilyName,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
