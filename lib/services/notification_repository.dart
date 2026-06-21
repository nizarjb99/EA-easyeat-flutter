import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification.dart';
import 'notification_service.dart';

class NotificationRepository {
  NotificationRepository({
    NotificationsApi? api,
  }) : _api = api ?? NotificationsApi();

  final NotificationsApi _api;

  String _cacheKeyNotifications(String customerId) => 'notifications_cache_$customerId';
  String _cacheKeyUnread(String customerId) => 'notifications_unread_cache_$customerId';

  Future<List<NotificationModel>> loadCachedNotifications(String customerId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKeyNotifications(customerId));
    if (raw == null || raw.isEmpty) return <NotificationModel>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => NotificationModel.fromJson(
                  e.map((key, value) => MapEntry(key.toString(), value)),
                ))
            .toList();
      }
    } catch (_) {}
    return <NotificationModel>[];
  }

  Future<void> saveCachedNotifications(
    String customerId,
    List<NotificationModel> notifications,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_cacheKeyNotifications(customerId), encoded);
  }

  Future<int?> loadCachedUnreadCount(String customerId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cacheKeyUnread(customerId));
  }

  Future<void> saveCachedUnreadCount(String customerId, int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheKeyUnread(customerId), count);
  }

  Future<NotificationsPageResponse> fetchNotifications({
    required String customerId,
    required String accessToken,
    required int page,
    required int limit,
    bool unreadOnly = false,
  }) {
    return _api.fetchCustomerNotifications(
      customerId: customerId,
      accessToken: accessToken,
      page: page,
      limit: limit,
      unreadOnly: unreadOnly,
    );
  }

  Future<int> fetchUnreadCount({
    required String customerId,
    required String accessToken,
  }) {
    return _api.countUnread(
      customerId: customerId,
      accessToken: accessToken,
    );
  }

  Future<NotificationModel> markAsRead({
    required String notificationId,
    required String accessToken,
  }) {
    return _api.markAsRead(
      notificationId: notificationId,
      accessToken: accessToken,
    );
  }

  Future<void> markAllAsRead({
    required String customerId,
    required String accessToken,
  }) {
    return _api.markAllAsRead(
      customerId: customerId,
      accessToken: accessToken,
    );
  }
}