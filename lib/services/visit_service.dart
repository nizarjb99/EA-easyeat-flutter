import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/visit.dart';
import '../utils/constants.dart';

class VisitService {
  final String _baseUrl = '${AppConstants.baseUrl}/visits';

  Future<Visit> createVisit({
    required String token,
    required String customerId,
    required String restaurantId,
    required String employeeId,
    required double billAmount,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'customer_id': customerId,
        'restaurant_id': restaurantId,
        'employee_id': employeeId,
        'billAmount': billAmount,
        'date': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final decoded = _safeDecode(response.body);
      throw Exception(
        decoded is Map<String, dynamic>
            ? (decoded['message']?.toString() ?? 'Failed to create visit')
            : 'Failed to create visit',
      );
    }

    final decoded = _safeDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      final visitJson = decoded['data'] ??
          decoded['visit'] ??
          decoded['item'] ??
          decoded;

      if (visitJson is Map<String, dynamic>) {
        return Visit.fromJson(visitJson);
      }
    }

    throw Exception('Unexpected response from visit creation');
  }

  dynamic _safeDecode(String body) {
    try {
      return json.decode(body);
    } catch (_) {
      return body;
    }
  }
}