class EmployeeProfile {
  final String name;
  final String? email;
  final String? phone;
  final String role; // 'owner' | 'staff'

  const EmployeeProfile({
    required this.name,
    this.email,
    this.phone,
    this.role = 'staff',
  });

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? 'staff',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'role': role,
    };
  }
}

class Employee {
  final String id;
  final String restaurantId;
  final EmployeeProfile profile;
  final String? refreshTokenHash;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Employee({
    required this.id,
    required this.restaurantId,
    required this.profile,
    this.refreshTokenHash,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  String get name => profile.name;
  String? get email => profile.email;
  String? get phone => profile.phone;
  String get role => profile.role;
  bool get isOwner => role == 'owner';
  bool get isStaff => role == 'staff';

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      restaurantId: (json['restaurant_id'] ?? json['restaurantId'] ?? '').toString(),
      profile: EmployeeProfile.fromJson(
        json['profile'] is Map<String, dynamic>
            ? json['profile'] as Map<String, dynamic>
            : <String, dynamic>{
                'name': json['name'],
                'email': json['email'],
                'phone': json['phone'],
                'role': json['role'],
              },
      ),
      refreshTokenHash: json['refreshTokenHash']?.toString(),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'restaurant_id': restaurantId,
      'profile': profile.toJson(),
      if (refreshTokenHash != null) 'refreshTokenHash': refreshTokenHash,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
