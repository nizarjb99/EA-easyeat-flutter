import 'package:flutter/material.dart';

enum NotificationType {
  pointsExpiring,
  newReward,
  newDish,
  reactivationOffer,
  promotion,
  newMessage,
  reviewLiked,
  pointsAwarded,
  unknown,
}

extension NotificationTypeX on NotificationType {
  String get apiValue {
    switch (this) {
      case NotificationType.pointsExpiring:
        return 'points_expiring';
      case NotificationType.newReward:
        return 'new_reward';
      case NotificationType.newDish:
        return 'new_dish';
      case NotificationType.reactivationOffer:
        return 'reactivation_offer';
      case NotificationType.promotion:
        return 'promotion';
      case NotificationType.newMessage:
        return 'new_message';
      case NotificationType.reviewLiked:
        return 'review_liked';
      case NotificationType.pointsAwarded:
        return 'points_awarded';
      case NotificationType.unknown:
        return 'unknown';
    }
  }

  String get label {
    switch (this) {
      case NotificationType.pointsExpiring:
        return 'Points a punt de caducar';
      case NotificationType.newReward:
        return 'Nova recompensa';
      case NotificationType.newDish:
        return 'Nou plat';
      case NotificationType.reactivationOffer:
        return 'Oferta de reactivació';
      case NotificationType.promotion:
        return 'Promoció';
      case NotificationType.newMessage:
        return 'Nou missatge';
      case NotificationType.reviewLiked:
        return 'Review destacada';
      case NotificationType.pointsAwarded:
        return 'Punts guanyats';
      case NotificationType.unknown:
        return 'Notificació';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.pointsExpiring:
      case NotificationType.pointsAwarded:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.newReward:
        return Icons.card_giftcard_outlined;
      case NotificationType.newDish:
        return Icons.restaurant_menu_outlined;
      case NotificationType.reactivationOffer:
        return Icons.local_offer_outlined;
      case NotificationType.promotion:
        return Icons.campaign_outlined;
      case NotificationType.newMessage:
        return Icons.chat_bubble_outline;
      case NotificationType.reviewLiked:
        return Icons.thumb_up_alt_outlined;
      case NotificationType.unknown:
        return Icons.notifications_none;
    }
  }

  static NotificationType fromString(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();
    switch (normalized) {
      case 'points_expiring':
        return NotificationType.pointsExpiring;
      case 'new_reward':
        return NotificationType.newReward;
      case 'new_dish':
        return NotificationType.newDish;
      case 'reactivation_offer':
        return NotificationType.reactivationOffer;
      case 'promotion':
        return NotificationType.promotion;
      case 'new_message':
        return NotificationType.newMessage;
      case 'review_liked':
        return NotificationType.reviewLiked;
      case 'points_awarded':
        return NotificationType.pointsAwarded;
      default:
        return NotificationType.unknown;
    }
  }
}

class NotificationModel {
  final String id;
  final String customerId;
  final String? restaurantId;
  final NotificationType type;
  final String title;
  final String message;
  final String? description;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final bool fcmSent;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const NotificationModel({
    required this.id,
    required this.customerId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.restaurantId,
    this.description,
    this.data = const <String, dynamic>{},
    this.readAt,
    this.fcmSent = false,
    this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> _mapData(dynamic value) {
      if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
      if (value is Map) {
        return value.map((key, dynamic val) => MapEntry(key.toString(), val));
      }
      return <String, dynamic>{};
    }

    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      final text = value.toString();
      return DateTime.tryParse(text);
    }

    bool _parseBool(dynamic value, {bool fallback = false}) {
      if (value == null) return fallback;
      if (value is bool) return value;
      final text = value.toString().trim().toLowerCase();
      if (text == 'true' || text == '1' || text == 'yes') return true;
      if (text == 'false' || text == '0' || text == 'no') return false;
      return fallback;
    }

    String _extractId(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map<String, dynamic>) {
        return (value['_id'] ?? value['id'] ?? '').toString();
      }
      if (value is Map) {
        return (value['_id'] ?? value['id'] ?? '').toString();
      }
      return value.toString();
    }

    final type = NotificationTypeX.fromString(json['type']);

    final createdAt = _parseDate(json['createdAt']) ?? DateTime.now();

    return NotificationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      customerId: (json['customer_id'] ?? json['customerId'] ?? '').toString(),
      restaurantId: json['restaurant_id'] != null
          ? _extractId(json['restaurant_id'])
          : (json['restaurantId'] != null ? _extractId(json['restaurantId']) : null),
      type: type,
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      description: json['description']?.toString(),
      data: _mapData(json['data']),
      isRead: _parseBool(json['isRead']),
      readAt: _parseDate(json['readAt']),
      fcmSent: _parseBool(json['fcmSent']),
      createdAt: createdAt,
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      '_id': id,
      'customer_id': customerId,
      if (restaurantId != null) 'restaurant_id': restaurantId,
      'type': type.apiValue,
      'title': title,
      'message': message,
      if (description != null) 'description': description,
      'data': data,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'fcmSent': fcmSent,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? customerId,
    String? restaurantId,
    NotificationType? type,
    String? title,
    String? message,
    String? description,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? readAt,
    bool? fcmSent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      restaurantId: restaurantId ?? this.restaurantId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      description: description ?? this.description,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      fcmSent: fcmSent ?? this.fcmSent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}