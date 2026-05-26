import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/employee.dart';
import '../models/employeeStats.dart';


class EmployeeService {
  final String _baseUrl = '${AppConstants.baseUrl}/employees';

  dynamic _decodeBody(http.Response response) {
    final dynamic body = json.decode(response.body);
    if (body is Map<String, dynamic> && body['data'] != null) {
      return body['data'];
    }
    return body;
  }

  Future<Employee> updateEmployee(
    String employeeId,
    Map<String, dynamic> data, {
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/$employeeId');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final response = await http
        .put(uri, headers: headers, body: json.encode(data))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to update employee profile (${response.statusCode})',
      );
    }

    final decoded = _decodeBody(response);
    return Employee.fromJson(decoded as Map<String, dynamic>);
  }

  Future<EmployeeStatistics> fetchEmployeeStatistics(
    String employeeId, {
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/$employeeId/statistics');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load employee statistics (${response.statusCode})',
      );
    }

    final dynamic body = json.decode(response.body);

    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return EmployeeStatistics.fromJson(data);
      }
      return EmployeeStatistics.fromJson(body);
    }

    throw Exception('Unexpected employee statistics response format');
  }

}
