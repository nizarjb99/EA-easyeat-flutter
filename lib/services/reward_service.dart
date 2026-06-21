import 'dart:convert';

import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/reward.dart';

class RewardService {
  final String _baseUrl = '${AppConstants.baseUrl}/rewards';

  Future<Map<String, String>> _headers(String? token) async {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
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
  ) async {
    final Map<String, dynamic> data = {
      'customer_id': customerId,
      'reward_id': rewardId,
      'employee_id': employeeId,
    };

    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/rewardRedemptions/'),
      headers: await _headers(token),
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

  /// Plays the roulette minigame. Returns { won: bool, reward: Reward?, pointsAfter: int }
  Future<Map<String, dynamic>> playRoulette(
    String rewardId,
    String customerId,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$rewardId/play-roulette'),
      headers: await _headers(token),
      body: json.encode({'customer_id': customerId}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      final body = json.decode(response.body);
      throw Exception(body['message'] ?? 'Failed to play roulette');
    }
  }

  /// Fetches the list of unlocked (free) reward IDs for a customer at a restaurant
  Future<List<String>> getUnlockedRewards(
    String customerId,
    String restaurantId,
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/unlocked/$customerId/$restaurantId'),
      headers: await _headers(token),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> ids = body['unlockedRewardIds'] ?? [];
      return ids.map((e) => e.toString()).toList();
    } else {
      throw Exception('Failed to fetch unlocked rewards');
    }
  }
}
