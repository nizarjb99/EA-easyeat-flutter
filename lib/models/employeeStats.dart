class EmployeeStatistics {
  final String id;
  final String employeeId;
  final int totalCustomersServed;
  final double totalRevenueGenerated;
  final int totalRewardApprovalsApproved;
  final int totalVisitsHandled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EmployeeStatistics({
    required this.id,
    required this.employeeId,
    required this.totalCustomersServed,
    required this.totalRevenueGenerated,
    required this.totalRewardApprovalsApproved,
    required this.totalVisitsHandled,
    this.createdAt,
    this.updatedAt,
  });

  factory EmployeeStatistics.fromJson(Map<String, dynamic> json) {
    return EmployeeStatistics(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      employeeId: (json['employee_id'] ?? json['employeeId'] ?? '').toString(),
      totalCustomersServed: _asInt(json['totalCustomersServed']),
      totalRevenueGenerated: _asDouble(json['totalRevenueGenerated']),
      totalRewardApprovalsApproved: _asInt(json['totalRewardApprovalsApproved']),
      totalVisitsHandled: _asInt(json['totalVisitsHandled']),
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