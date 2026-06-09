import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/notification.dart';
import 'device_token_service.dart';
import 'local_notification_service.dart';

/// Top-level handler required by Firebase for background messages.
///
/// Must be a top-level function (not a class method) and is registered once
/// in [main] via [FirebaseMessaging.onBackgroundMessage].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No UI work here – the app may not be running.
  debugPrint('[FCM background] ${message.messageId}: '
      '${message.notification?.title}');
}

class FcmService {
  FcmService({
    LocalNotificationService? localNotificationService,
    DeviceTokenApi? deviceTokenApi,
  })  : _localNotificationService =
      localNotificationService ?? LocalNotificationService.instance,
        _deviceTokenApi = deviceTokenApi ?? DeviceTokenApi();

  final LocalNotificationService _localNotificationService;
  final DeviceTokenApi _deviceTokenApi;

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;

  // ──────────────────────────────────────────────────────────────────────────
  // Initialise
  // ──────────────────────────────────────────────────────────────────────────

  /// Sets up FCM listeners and registers the device token with the backend.
  ///
  /// [getAccessToken] is a **getter callback** rather than a plain string so
  /// the token-refresh subscription always uses the latest token – avoiding
  /// the bug where a stale token is captured at initialisation time.
  Future<void> initialize({
    required String? customerId,
    // Callback instead of a plain String so the refresh listener can read
    // the current token at the time the new FCM token arrives.
    required String? Function() getAccessToken,
    required Future<void> Function(Map<String, dynamic> payload)
    onNotificationTap,
    required void Function(NotificationModel notification)
    onForegroundNotification,
  }) async {
    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    // ── Permissions ──────────────────────────────────────────────────────────
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // ── Local notification plugin ────────────────────────────────────────────
    await _localNotificationService.initialize(onTap: onNotificationTap);

    // ── Foreground messages ──────────────────────────────────────────────────
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

    // ── Notification tap while app was in background ─────────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onNotificationTap(Map<String, dynamic>.from(message.data));
    });

    // ── App launched by tapping a notification (terminated state) ────────────
    final initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await onNotificationTap(Map<String, dynamic>.from(initialMessage.data));
    }

    // ── Register current token ───────────────────────────────────────────────
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null && customerId != null && customerId.isNotEmpty) {
      await _deviceTokenApi.registerToken(
        customerId: customerId,
        token: token,
        platform: defaultTargetPlatform.name,
        // Use the getter so we always have the most recent access token.
        accessToken: getAccessToken(),
      );
    }

    // ── React to token rotation ──────────────────────────────────────────────
    // Tokens can be rotated by Firebase at any time.  We re-register using
    // the getter callback so we always send the current auth token, even if
    // it was refreshed after FCM was initialised.
    _tokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          if (customerId != null && customerId.isNotEmpty) {
            await _deviceTokenApi.registerToken(
              customerId: customerId,
              token: newToken,
              platform: defaultTargetPlatform.name,
              accessToken: getAccessToken(), // current token at rotation time
            );
          }
        });

    _initialized = true;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Dispose
  // ──────────────────────────────────────────────────────────────────────────

  /// Cancels the token-refresh subscription and unregisters the device token
  /// from the backend so the user no longer receives notifications after
  /// logging out.
  Future<void> dispose({String? accessToken}) async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    if (!kIsWeb) {
      // Unregister the current FCM token from the backend.
      final cachedToken = await _deviceTokenApi.getCachedToken();
      if (cachedToken != null && cachedToken.isNotEmpty) {
        await _deviceTokenApi.unregisterToken(
          token: cachedToken,
          accessToken: accessToken,
        );
      }

      // Optionally delete the FCM registration on this device entirely.
      // This prevents Firebase from delivering any messages until the next
      // login and re-registration.  Comment out if you want the token to
      // survive for silent data messages.
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (e) {
        debugPrint('[FcmService] deleteToken error: $e');
      }
    }

    _initialized = false;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  NotificationModel _notificationFromRemoteMessage(RemoteMessage message) {
    final payload = Map<String, dynamic>.from(message.data);
    final type = NotificationTypeX.fromString(payload['type']);

    return NotificationModel(
      id: (payload['notification_id'] ??
          message.messageId ??
          message.hashCode.toString())
          .toString(),
      customerId: (payload['customer_id'] ?? '').toString(),
      restaurantId: payload['restaurant_id']?.toString(),
      type: type,
      title: message.notification?.title ??
          (payload['title']?.toString() ?? type.label),
      message: message.notification?.body ??
          (payload['message']?.toString() ?? ''),
      description: payload['description']?.toString(),
      data: payload,
      isRead: false,
      fcmSent: true,
      createdAt: DateTime.now(),
    );
  }
}