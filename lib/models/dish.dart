// lib/models/dish.dart

class Dish {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final String section; // 'Starters' | 'Mains' | 'Desserts' | 'Drinks' | 'Sides' | 'Specials'
  final double price;
  final List<String> images;
  final bool active;
  final List<String> availableAt; // ['breakfast', 'brunch', 'lunch', 'happy-hour', 'dinner', 'all-day']
  final List<String> ingredients;
  final List<String> allergens; // gluten, shellfish, nuts, dairy, eggs, soy, fish, sesame, mustard, celery, lupins, molluscs, sulphites
  final List<String> dietaryFlags; // vegan, vegetarian, gluten-free, halal, kosher, dairy-free, nut-free
  final List<String> flavorProfile; // spicy, mild, sweet, sour, salty, bitter, umami, smoky, rich, light, creamy, tangy, fresh, hearty, nutty
  final List<String> cuisineTags; // Italian, Japanese, Sushi, Mexican, Chinese, Indian, Thai, French, Mediterranean, Spanish, Greek, Turkish, Korean, Vietnamese, German, Brazilian, Peruvian, Vegan, Vegetarian, Seafood, Meat, Pizzeria, Gluten Free, Gourmet, Fast Food, Street Food, Wine, Tapas, Gelateria, Sandwich, Ramen, Cafeteria
  final String? portionSize; // 'small' | 'medium' | 'large' | 'sharing'
  final double avgRating;
  final int ratingsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Reward-related fields (for compatibility with backend reward endpoints)
  final bool isReward;
  final int rewardPoints;
  final String? rewardDescription;

  Dish({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.section,
    required this.price,
    this.images = const [],
    required this.active,
    this.availableAt = const [],
    this.ingredients = const [],
    this.allergens = const [],
    this.dietaryFlags = const [],
    this.flavorProfile = const [],
    this.cuisineTags = const [],
    this.portionSize,
    this.avgRating = 0.0,
    this.ratingsCount = 0,
    this.createdAt,
    this.updatedAt,
    this.isReward = false,
    this.rewardPoints = 0,
    this.rewardDescription,
  });

  /// Create a Dish from JSON (from backend API response)
  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      restaurantId: _extractRestaurantId(json),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      section: json['section']?.toString() ?? 'Mains',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      images: _parseList<String>(json['images'] ?? []),
      active: json['active'] as bool? ?? true,
      availableAt: _parseList<String>(json['availableAt'] ?? []),
      ingredients: _parseList<String>(json['ingredients'] ?? []),
      allergens: _parseList<String>(json['allergens'] ?? []),
      dietaryFlags: _parseList<String>(json['dietaryFlags'] ?? []),
      flavorProfile: _parseList<String>(json['flavorProfile'] ?? []),
      cuisineTags: _parseList<String>(json['cuisineTags'] ?? []),
      portionSize: json['portionSize']?.toString(),
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      ratingsCount: (json['ratingsCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      isReward: json['isReward'] as bool? ?? false,
      rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
      rewardDescription: json['rewardDescription']?.toString(),
    );
  }

  /// Convert Dish to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'restaurant_id': restaurantId,
      'name': name,
      if (description != null) 'description': description,
      'section': section,
      'price': price,
      'images': images,
      'active': active,
      'availableAt': availableAt,
      'ingredients': ingredients,
      'allergens': allergens,
      'dietaryFlags': dietaryFlags,
      'flavorProfile': flavorProfile,
      'cuisineTags': cuisineTags,
      if (portionSize != null) 'portionSize': portionSize,
      'avgRating': avgRating,
      'ratingsCount': ratingsCount,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'isReward': isReward,
      'rewardPoints': rewardPoints,
      if (rewardDescription != null) 'rewardDescription': rewardDescription,
    };
  }

  /// Copy constructor with optional field overrides
  Dish copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? description,
    String? section,
    double? price,
    List<String>? images,
    bool? active,
    List<String>? availableAt,
    List<String>? ingredients,
    List<String>? allergens,
    List<String>? dietaryFlags,
    List<String>? flavorProfile,
    List<String>? cuisineTags,
    String? portionSize,
    double? avgRating,
    int? ratingsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isReward,
    int? rewardPoints,
    String? rewardDescription,
  }) {
    return Dish(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      section: section ?? this.section,
      price: price ?? this.price,
      images: images ?? this.images,
      active: active ?? this.active,
      availableAt: availableAt ?? this.availableAt,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      dietaryFlags: dietaryFlags ?? this.dietaryFlags,
      flavorProfile: flavorProfile ?? this.flavorProfile,
      cuisineTags: cuisineTags ?? this.cuisineTags,
      portionSize: portionSize ?? this.portionSize,
      avgRating: avgRating ?? this.avgRating,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isReward: isReward ?? this.isReward,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      rewardDescription: rewardDescription ?? this.rewardDescription,
    );
  }

  @override
  String toString() {
    return 'Dish(id: $id, name: $name, restaurantId: $restaurantId, price: $price, section: $section, active: $active)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Dish && other.id == id && other.restaurantId == restaurantId;
  }

  @override
  int get hashCode => id.hashCode ^ restaurantId.hashCode;

  // =========================================================================
  // Helper methods
  // =========================================================================

  /// Check if dish is available at a specific service period
  bool isAvailableAt(String servicePeriod) => availableAt.contains(servicePeriod);

  /// Check if dish has any allergens
  bool hasAllergens() => allergens.isNotEmpty;

  /// Check if dish matches dietary flag
  bool hasDietaryFlag(String flag) => dietaryFlags.contains(flag);

  /// Check if dish has a flavor profile
  bool hasFlavorProfile(String flavor) => flavorProfile.contains(flavor);

  /// Check if dish has a cuisine tag
  bool hasCuisineTag(String tag) => cuisineTags.contains(tag);

  /// Get rating as a formatted string
  String get formattedRating => avgRating > 0 ? avgRating.toStringAsFixed(1) : 'N/A';

  /// Check if dish is a reward
  bool get isRewardEligible => isReward || rewardPoints > 0;

  // =========================================================================
  // Private helper functions
  // =========================================================================

  /// Extract restaurant ID from various possible JSON formats
  static String _extractRestaurantId(Map<String, dynamic> json) {
    if (json['restaurantId'] != null) return json['restaurantId'].toString();
    if (json['restaurant_id'] != null) return json['restaurant_id'].toString();
    if (json['restaurant'] != null) {
      final restaurant = json['restaurant'];
      if (restaurant is String) return restaurant;
      if (restaurant is Map<String, dynamic> && restaurant['_id'] != null) {
        return restaurant['_id'].toString();
      }
    }
    return '';
  }

  /// Parse a list from JSON (handles nulls and non-list values)
  static List<T> _parseList<T>(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) {
        if (T == String) return item.toString() as T;
        return item as T;
      }).toList();
    }
    return [];
  }
}

