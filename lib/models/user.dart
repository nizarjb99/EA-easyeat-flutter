import 'restaurant.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'customer', 'staff', 'owner', 'admin'
  final Restaurant? restaurant; 

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.restaurant,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handling nested profile from /employees or flat from /auth/login
    final profile = json['profile'] as Map<String, dynamic>?;
    
    final id = (json['_id'] ?? json['id'] ?? '').toString();
    final name = profile?['name'] ?? json['name'] ?? '';
    final email = profile?['email'] ?? json['email'] ?? '';
    final role = profile?['role'] ?? json['role'] ?? 'customer';
    
    // In backend can be restaurant_id (ID) or restaurant (Object)
    final restData = json['restaurant_id'] ?? json['restaurant'] ?? json['organization'];

    Restaurant? rest;
    if (restData != null) {
      if (restData is Map<String, dynamic>) {
        rest = Restaurant.fromJson(restData);
      } else {
        rest = Restaurant(
          id: restData.toString(),
          name: 'Mi Restaurante',
          employees: [],
        );
      }
    }

    return User(
      id: id,
      name: name,
      email: email,
      role: role,
      restaurant: rest,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'role': role,
      'restaurant': restaurant?.id,
    };
  }
}
