// lib/models/reward.dart

class Reward {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final int pointsRequired;
  final bool active;
  final DateTime? expiry;
  final int timesRedeemed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Reward({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.pointsRequired,
    required this.active,
    this.expiry,
    this.timesRedeemed = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      restaurantId: (json['restaurantId'] ?? json['restaurant'] ?? '').toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      pointsRequired: (json['pointsRequired'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? true,
      expiry: json['expiry'] != null ? DateTime.tryParse(json['expiry'].toString()) : null,
      timesRedeemed: (json['timesRedeemed'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'restaurantId': restaurantId,
      'name': name,
      if (description != null) 'description': description,
      'pointsRequired': pointsRequired,
      'active': active,
      if (expiry != null) 'expiry': expiry!.toIso8601String(),
      'timesRedeemed': timesRedeemed,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Check if the reward is still valid (active and not expired)
  bool get isValid {
    if (!active) return false;
    if (expiry != null && DateTime.now().isAfter(expiry!)) return false;
    return true;
  }

  /// Get days until expiry, or null if not expiring
  int? get daysUntilExpiry {
    if (expiry == null) return null;
    final diff = expiry!.difference(DateTime.now());
    return diff.inDays;
  }

  /// Check if expiring soon (within 7 days)
  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days > 0 && days <= 7;
  }
}

