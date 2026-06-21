import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification.dart';
import '../providers/auth_provider.dart';
import '../screens/_common/navigation_screen.dart';
import '../screens/_common/notification_screen.dart';
import '../screens/_common/popup_chat_screen.dart';
import '../screens/_common/restaurant_detail_screen.dart';
import '../screens/_customer/points_wallet_screen.dart';
import '../services/restaurant_service.dart';

class NotificationRouter {
  static Future<void> routeFromPayload(
    BuildContext context,
    Map<String, dynamic> payload,
  ) async {
    final type = NotificationTypeX.fromString(payload['type']);
    final restaurantId = _string(payload['restaurant_id']) ?? _string(payload['restaurantId']);
    final customerId = _string(payload['customer_id']) ?? _string(payload['customerId']);
    final conversationId = _string(payload['conversation_id']) ?? _string(payload['conversationId']);
    final reviewId = _string(payload['review_id']) ?? _string(payload['reviewId']);
    final rewardId = _string(payload['reward_id']) ?? _string(payload['rewardId']);
    final dishId = _string(payload['dish_id']) ?? _string(payload['dishId']);

    if (!context.mounted) return;

    final auth = context.read<AuthProvider>();
    final token = auth.accessToken;

    switch (type) {
      case NotificationType.newMessage:
        if (restaurantId != null && restaurantId.isNotEmpty) {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => PopupChatScreen(restaurantId: restaurantId),
          );
          return;
        }
        // El xat actual no obre directament per conversationId.
        // Si no hi ha restaurantId, fem fallback al centre de notificacions.
        await _openNotifications(context);
        return;

      case NotificationType.reviewLiked:
        if (restaurantId != null && restaurantId.isNotEmpty) {
          await _openRestaurantDetail(context, restaurantId: restaurantId, accessToken: token);
          return;
        }
        // No hi ha ReviewDetailScreen al workspace.
        await _openNotifications(context);
        return;

      case NotificationType.newReward:
        await _openPointsWallet(context);
        return;

      case NotificationType.pointsAwarded:
      case NotificationType.pointsExpiring:
        await _openPointsWallet(context);
        return;

      case NotificationType.newDish:
      case NotificationType.promotion:
      case NotificationType.reactivationOffer:
        if (restaurantId != null && restaurantId.isNotEmpty) {
          await _openRestaurantDetail(context, restaurantId: restaurantId, accessToken: token);
          return;
        }
        await _openNotifications(context);
        return;

      case NotificationType.unknown:
        await _openNotifications(context);
        return;
    }

    // Fallback per qualsevol camp extra que pugui venir al payload.
    if (conversationId != null || reviewId != null || rewardId != null || dishId != null || customerId != null) {
      await _openNotifications(context);
    }
  }

  static Future<void> routeFromNotificationModel(
    BuildContext context,
    NotificationModel notification,
  ) async {
    await routeFromPayload(context, {
      'type': notification.type.apiValue,
      'customer_id': notification.customerId,
      if (notification.restaurantId != null) 'restaurant_id': notification.restaurantId,
      ...notification.data,
    });
  }

  static Future<void> _openNotifications(BuildContext context) async {
    await Navigator.pushNamed(context, '/notifications');
  }

  static Future<void> _openPointsWallet(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      await Navigator.pushNamed(context, '/notifications');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PointsWalletScreen()),
    );
  }

  static Future<void> _openRestaurantDetail(
    BuildContext context, {
    required String restaurantId,
    String? accessToken,
  }) async {
    final restaurantService = RestaurantService();

    try {
      final restaurant = await restaurantService.fetchRestaurantById(
        restaurantId,
        accessToken: accessToken,
      );

      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RestaurantDetailScreen(restaurant: restaurant),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        await Navigator.pushNamed(context, '/notifications');
      }
    }
  }

  static String? _string(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}