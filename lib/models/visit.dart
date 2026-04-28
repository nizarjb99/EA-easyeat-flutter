class Visit {
  final String id;
  final String customerId;
  final String? customerName;
  final String restaurantId;
  final DateTime date;
  final double pointsEarned;
  final double billAmount;
  final DateTime? deletedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Visit({
    required this.id,
    required this.customerId,
    this.customerName,
    required this.restaurantId,
    required this.date,
    this.pointsEarned = 0.0,
    this.billAmount = 0.0,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    // customer_id can be a String or a Map with 'name' if populated
    String? cName;
    String cId = '';

    if (json['customer_id'] is Map<String, dynamic>) {
      final cMap = json['customer_id'] as Map<String, dynamic>;
      cId = (cMap['_id'] ?? cMap['id'] ?? '').toString();
      cName = (cMap['name'] ?? '').toString();
    } else {
      cId = (json['customer_id'] ?? '').toString();
      cName = json['customer_name']?.toString();
    }

    return Visit(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      customerId: cId,
      customerName: cName,
      restaurantId: (json['restaurant_id'] ?? '').toString(),
      date: DateTime.parse(json['date'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      pointsEarned: (json['pointsEarned'] ?? 0).toDouble(),
      billAmount: (json['billAmount'] ?? 0).toDouble(),
      deletedAt: json['deletedAt'] != null ? DateTime.parse(json['deletedAt']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'customer_id': customerId,
      'restaurant_id': restaurantId,
      'date': date.toIso8601String(),
      'pointsEarned': pointsEarned,
      'billAmount': billAmount,
      'deletedAt': deletedAt?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
