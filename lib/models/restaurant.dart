class Employee {
  final String id;
  final String name;

  Employee({required this.id, required this.name});

  factory Employee.fromJson(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      final String id = (raw['_id'] ?? raw['id'] ?? '').toString();
      final String name = (raw['name'] ?? '').toString();
      return Employee(id: id, name: name.isEmpty ? id : name);
    }
    final String value = raw.toString();
    return Employee(id: value, name: value);
  }
}

class Restaurant {
  final String id;
  final String name;
  final List<Employee> employees;

  Restaurant({required this.id, required this.name, required this.employees});

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    
    return Restaurant(
      id: json['_id'] ?? json['id'] ?? '',
      name: profile?['name'] ?? json['name'] ?? 'Restaurante',
      employees: (json['employees'] as List<dynamic>?)
              ?.map((dynamic e) => Employee.fromJson(e))
              .toList() ?? [],
    );
  }
}
