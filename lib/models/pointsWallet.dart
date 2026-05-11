class RestaurantWalletRef {
  final String id;
  final String? name;
  final String? city;
  final String? address;

  RestaurantWalletRef({
    required this.id,
    this.name,
    this.city,
    this.address,
  });

  factory RestaurantWalletRef.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final location = profile is Map<String, dynamic> ? profile['location'] : null;

    return RestaurantWalletRef(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: profile is Map<String, dynamic> ? profile['name']?.toString() : null,
      city: location is Map<String, dynamic> ? location['city']?.toString() : null,
      address: location is Map<String, dynamic> ? location['address']?.toString() : null,
    );
  }
}

class PointsWallet {
  final String id;
  final String customerId;
  final RestaurantWalletRef restaurant;
  final int points;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PointsWallet({
    required this.id,
    required this.customerId,
    required this.restaurant,
    required this.points,
    this.createdAt,
    this.updatedAt,
  });

  factory PointsWallet.fromJson(Map<String, dynamic> json) {
    final rawRestaurant = json['restaurant_id'];

    final restaurant = rawRestaurant is Map<String, dynamic>
        ? RestaurantWalletRef.fromJson(rawRestaurant)
        : RestaurantWalletRef(id: rawRestaurant?.toString() ?? '');

    return PointsWallet(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      customerId: (json['customer_id'] ?? '').toString(),
      restaurant: restaurant,
      points: (json['points'] as num?)?.toInt() ??
          int.tryParse(json['points']?.toString() ?? '') ??
          0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'customer_id': customerId,
      'restaurant_id': restaurant.id,
      'points': points,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}