class CustomerStatistics {
  final String id;
  final String customerId;
  final int currentPointsBalance;
  final int totalVisits;
  final double averageReviewRating;
  final int favoriteRestaurants;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerStatistics({
    required this.id,
    required this.customerId,
    required this.currentPointsBalance,
    required this.totalVisits,
    required this.averageReviewRating,
    required this.favoriteRestaurants,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerStatistics.fromJson(Map<String, dynamic> json) {
    return CustomerStatistics(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      customerId: (json['customer_id'] ?? json['customerId'] ?? '').toString(),
      currentPointsBalance: _asInt(json['currentPointsBalance']),
      totalVisits: _asInt(json['totalVisits']),
      averageReviewRating: _asDouble(json['averageReviewRating']),
      favoriteRestaurants: _asInt(json['favoriteRestaurants']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return num.tryParse(value?.toString() ?? '')?.toInt() ?? 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

