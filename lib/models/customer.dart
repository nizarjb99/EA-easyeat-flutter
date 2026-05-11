class Customer {
  final String id;
  final String name;
  final String email;
  final String? password;
  final String? refreshTokenHash;
  final bool isActive;
  final DateTime? deletedAt;
  final List<String> profilePictures;
  final List<String> pointsWallet; // List of ObjectIds as Strings
  final List<String> visitHistory; // List of ObjectIds as Strings
  final List<String> favoriteRestaurants; // List of ObjectIds as Strings
  final List<String> badges; // List of ObjectIds as Strings
  final List<String> reviews; // List of ObjectIds as Strings
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    this.password,
    this.refreshTokenHash,
    this.isActive = true,
    this.deletedAt,
    this.profilePictures = const [],
    this.pointsWallet = const [],
    this.visitHistory = const [],
    this.favoriteRestaurants = const [],
    this.badges = const [],
    this.reviews = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'],
      refreshTokenHash: json['refreshTokenHash'],
      isActive: json['isActive'] ?? true,
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      profilePictures: List<String>.from(json['profilePictures'] ?? []),
      pointsWallet: List<String>.from(json['pointsWallet'] ?? []),
      visitHistory: List<String>.from(json['visitHistory'] ?? []),
      favoriteRestaurants: List<String>.from(json['favoriteRestaurants'] ?? []),
      badges: List<String>.from(json['badges'] ?? []),
      reviews: List<String>.from(json['reviews'] ?? []),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      if (password != null) 'password': password,
      if (refreshTokenHash != null) 'refreshTokenHash': refreshTokenHash,
      'isActive': isActive,
      'deletedAt': deletedAt?.toIso8601String(),
      'profilePictures': profilePictures,
      'pointsWallet': pointsWallet,
      'visitHistory': visitHistory,
      'favoriteRestaurants': favoriteRestaurants,
      'badges': badges,
      'reviews': reviews,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
