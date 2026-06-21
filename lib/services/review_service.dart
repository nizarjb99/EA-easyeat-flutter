import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../models/review.dart';

class ReviewService {
  final String _baseUrl = '${AppConstants.baseUrl}/restaurants';

  Future<List<Review>> fetchReviewsByRestaurant(
    String restaurantId, {
    String? accessToken,
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse('$_baseUrl/$restaurantId/reviews?page=$page&limit=$limit');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to load reviews (${response.statusCode})');
      }

      final dynamic body = json.decode(response.body);
      final List<dynamic> list = _extractList(body);

      return list
          .whereType<Map<String, dynamic>>()
          .map(Review.fromJson)
          .toList();
    } catch (e) {
      throw Exception('Error loading reviews: $e');
    }
  }

  Future<Review> createReview(String restaurantId, Review review, {String? accessToken}) async {
    final uri = Uri.parse('$_baseUrl/$restaurantId/reviews');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final bodyJson = json.encode(review.toJson());

    try {
      final response = await http.post(uri, headers: headers, body: bodyJson);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to create review (${response.statusCode})');
      }
      final dynamic body = json.decode(response.body);
      final data = body['data'] ?? body;
      return Review.fromJson(data);
    } catch (e) {
      throw Exception('Error creating review: $e');
    }
  }

  Future<void> likeReview(String restaurantId, String reviewId, {String? accessToken}) async {
    final uri = Uri.parse('$_baseUrl/$restaurantId/reviews/$reviewId/like');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    try {
      final response = await http.post(uri, headers: headers);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to like review (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error liking review: $e');
    }
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List<dynamic>) return body;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List<dynamic>) return data;

      final items = body['items'];
      if (items is List<dynamic>) return items;

      final results = body['results'];
      if (results is List<dynamic>) return results;
    }
    return const <dynamic>[];
  }
}
