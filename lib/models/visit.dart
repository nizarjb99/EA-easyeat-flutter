class Visit {
  final String id;
  final String customerId;
  final String? customerName;
  final String restaurantId;
  final DateTime date;
  final double? pointsEarned;
  final double? billAmount;

  Visit({
    required this.id,
    required this.customerId,
    this.customerName,
    required this.restaurantId,
    required this.date,
    this.pointsEarned,
    this.billAmount,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    // customer_id can be a String or a Map with 'name'
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
      pointsEarned: json['pointsEarned']?.toDouble(),
      billAmount: json['billAmount']?.toDouble(),
    );
  }
}
