import 'dart:convert';

import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/reward.dart';

class RewardService {
  final String _baseUrl = '${AppConstants.baseUrl}/rewards';

  Future<Map<String, String>> _headers(String? token, String? key) async {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      if (key != null) 'Idempotency-Key': key,
    };
  }

  Future<Reward> fetchRewardById(String rewardId, {String? accessToken}) async {
    final uri = Uri.parse('$_baseUrl/$rewardId');

    final response = await http.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load reward (${response.statusCode})');
    }

    final dynamic body = json.decode(response.body);

    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return Reward.fromJson(data);
      return Reward.fromJson(body);
    }

    throw Exception('Unexpected reward response format');
  }

  Future redeemReward(
    String customerId,
    String rewardId,
    String employeeId,
    String token,
    String key,
  ) async {
    final Map<String, dynamic> data = {
      'customer_id': customerId,
      'reward_id': rewardId,
      'employee_id': employeeId,
    };

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/rewardRedemptions/'),
      headers: await _headers(token, key),
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
        json.decode(response.body)['message'] ?? 'Failed to redeem reward',
      );
    }
  }

  // Uncoment if needed
  // List<dynamic> _extractList(dynamic body) {
  //   if (body is List<dynamic>) return body;
  //   if (body is Map<String, dynamic>) {
  //     final data = body['data'];
  //     if (data is List<dynamic>) return data;

  //     final items = body['items'];
  //     if (items is List<dynamic>) return items;

  //     final results = body['results'];
  //     if (results is List<dynamic>) return results;
  //   }
  //   return const <dynamic>[];
  // }
}
