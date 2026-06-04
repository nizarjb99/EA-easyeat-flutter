import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/notification.dart';
import '../utils/constants.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized']);

  @override
  String toString() => message;
}

class NotificationsPageResponse {
  final List<NotificationModel> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  const NotificationsPageResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });
}

class NotificationsApi {
  NotificationsApi({
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
    int retryCount = 1,
  })  : _client = client ?? http.Client(),
        _timeout = timeout,
        _retryCount = retryCount;

  final http.Client _client;
  final Duration _timeout;
  final int _retryCount;

  String get _baseUrl => '${AppConstants.baseUrl}/notifications';

  Future<Map<String, String>> _headers(String? token) async {
    return <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() action,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt <= _retryCount; attempt++) {
      try {
        return await action().timeout(_timeout);
      } on TimeoutException catch (e) {
        lastError = e;
      } on SocketException catch (e) {
        lastError = e;
      }
      if (attempt < _retryCount) {
        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }
    throw Exception('Request failed: $lastError');
  }

  dynamic _decodeBody(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic> && decoded['data'] != null) {
      return decoded['data'];
    }
    return decoded;
  }

  List<Map<String, dynamic>> _extractNotificationList(dynamic body) {
    if (body is List) {
      return body
          .whereType<Map>()
          .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }

    if (body is Map<String, dynamic>) {
      for (final key in const ['items', 'results', 'docs', 'notifications', 'data']) {
        final value = body[key];
        if (value is List) {
          return value
              .whereType<Map>()
              .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
              .toList();
        }
      }

      if (body.containsKey('_id') || body.containsKey('id')) {
        return [body];
      }
    }

    return <Map<String, dynamic>>[];
  }

  int _extractInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  Future<NotificationsPageResponse> fetchCustomerNotifications({
    required String customerId,
    required String accessToken,
    required int page,
    required int limit,
    bool unreadOnly = false,
  }) async {
    final path = unreadOnly ? 'customer/$customerId/unread' : 'customer/$customerId';
    final uri = Uri.parse('$_baseUrl/$path?page=$page&limit=$limit');

    final response = await _sendWithRetry(
      () async => _client.get(uri, headers: await _headers(accessToken)),
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to load notifications (${response.statusCode})');
    }

    final body = _decodeBody(response);
    final list = _extractNotificationList(body)
        .map(NotificationModel.fromJson)
        .toList();

    final total = body is Map<String, dynamic>
        ? _extractInt(body['total'], fallback: list.length)
        : list.length;

    final hasMore = body is Map<String, dynamic>
        ? (body['hasMore'] as bool?) ??
            (body['hasNextPage'] as bool?) ??
            (page * limit < total)
        : list.length >= limit;

    return NotificationsPageResponse(
      items: list,
      page: page,
      limit: limit,
      total: total,
      hasMore: hasMore,
    );
  }

  Future<int> countUnread({
    required String customerId,
    required String accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/customer/$customerId/count-unread');

    final response = await _sendWithRetry(
      () async => _client.get(uri, headers: await _headers(accessToken)),
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to count unread notifications (${response.statusCode})');
    }

    final body = _decodeBody(response);

    if (body is int) return body;
    if (body is num) return body.toInt();
    if (body is Map<String, dynamic>) {
      return _extractInt(
        body['count'] ?? body['unreadCount'] ?? body['totalUnread'] ?? body['value'],
        fallback: 0,
      );
    }

    return 0;
  }

  Future<NotificationModel> markAsRead({
    required String notificationId,
    required String accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/$notificationId/read');

    final response = await _sendWithRetry(
      () async => _client.patch(uri, headers: await _headers(accessToken)),
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to mark notification as read (${response.statusCode})');
    }

    final body = _decodeBody(response);
    if (body is Map<String, dynamic>) {
      return NotificationModel.fromJson(body);
    }

    throw Exception('Unexpected response while marking notification as read');
  }

  Future<void> markAllAsRead({
    required String customerId,
    required String accessToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/customer/$customerId/read-all');

    final response = await _sendWithRetry(
      () async => _client.patch(uri, headers: await _headers(accessToken)),
    );

    if (response.statusCode == 401) {
      throw UnauthorizedException();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to mark all notifications as read (${response.statusCode})');
    }
  }
}