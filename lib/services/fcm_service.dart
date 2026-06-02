import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/notification.dart';
import 'device_token_service.dart';
import 'local_notification_service.dart';

class FcmService {
  FcmService({
    LocalNotificationService? localNotificationService,
    DeviceTokenApi? deviceTokenApi,
  })  : _localNotificationService = localNotificationService ?? LocalNotificationService.instance,
        _deviceTokenApi = deviceTokenApi ?? DeviceTokenApi();

  final LocalNotificationService _localNotificationService;
  final DeviceTokenApi _deviceTokenApi;

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> initialize({
    required String? customerId,
    required String? accessToken,
    required Future<void> Function(Map<String, dynamic> payload) onNotificationTap,
    required void Function(NotificationModel notification) onForegroundNotification,
  }) async {
    if (_initialized) return;

    if (kIsWeb) {
      // FCM web requereix configuració addicional. Aquest projecte està orientat a mobile.
      _initialized = true;
      return;
    }

    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _localNotificationService.initialize(
      onTap: onNotificationTap,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = Map<String, dynamic>.from(message.data);
      final notification = _notificationFromRemoteMessage(message);

      onForegroundNotification(notification);

      await _localNotificationService.showForegroundNotification(
        id: message.hashCode,
        title: message.notification?.title ?? notification.title,
        body: message.notification?.body ?? notification.message,
        payload: data,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onNotificationTap(Map<String, dynamic>.from(message.data));
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await onNotificationTap(Map<String, dynamic>.from(initialMessage.data));
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && customerId != null && customerId.isNotEmpty) {
      await _deviceTokenApi.registerToken(
        customerId: customerId,
        token: token,
        platform: defaultTargetPlatform.name,
        accessToken: accessToken,
      );
    }

    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (customerId != null && customerId.isNotEmpty) {
        await _deviceTokenApi.registerToken(
          customerId: customerId,
          token: newToken,
          platform: defaultTargetPlatform.name,
          accessToken: accessToken,
        );
      }
    });

    _initialized = true;
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _initialized = false;
  }

  NotificationModel _notificationFromRemoteMessage(RemoteMessage message) {
    final payload = Map<String, dynamic>.from(message.data);
    final type = NotificationTypeX.fromString(payload['type']);

    return NotificationModel(
      id: (payload['notification_id'] ?? message.messageId ?? message.hashCode.toString()).toString(),
      customerId: (payload['customer_id'] ?? '').toString(),
      restaurantId: payload['restaurant_id']?.toString(),
      type: type,
      title: message.notification?.title ?? (payload['title']?.toString() ?? type.label),
      message: message.notification?.body ?? (payload['message']?.toString() ?? ''),
      description: payload['description']?.toString(),
      data: payload,
      isRead: false,
      fcmSent: true,
      createdAt: DateTime.now(),
    );
  }
}