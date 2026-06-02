import 'dart:async';

import 'package:flutter/material.dart';

import '../models/notification.dart';
import '../providers/auth_provider.dart';
import '../services/notification_repository.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  NotificationProvider({
    NotificationRepository? repository,
    String? initialCustomerId,
    String? initialAccessToken,
  })  : _repository = repository ?? NotificationRepository(),
        _customerId = initialCustomerId,
        _accessToken = initialAccessToken;

  final NotificationRepository _repository;

  String? _customerId;
  String? _accessToken;
  String _authSignature = '';

  final List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _pageSize = 20;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;
  bool get hasSession => _customerId != null && _customerId!.isNotEmpty && _accessToken != null && _accessToken!.isNotEmpty;

  void bindAuth(AuthProvider auth) {
    final signature = '${auth.accountType}:${auth.id}:${auth.accessToken}';
    if (signature == _authSignature) return;

    _authSignature = signature;

    if (!auth.isLoggedIn || !auth.isCustomer || auth.id == null || auth.accessToken == null) {
      clearSession();
      return;
    }

    _customerId = auth.id;
    _accessToken = auth.accessToken;

    unawaited(refresh());
    unawaited(refreshUnreadCount());
  }

  void clearSession() {
    _customerId = null;
    _accessToken = null;
    _notifications.clear();
    _currentPage = 1;
    _hasMore = true;
    _isLoading = false;
    _isLoadingMore = false;
    _unreadCount = 0;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refresh({int pageSize = 20}) async {
    if (!hasSession) {
      clearSession();
      return;
    }

    _pageSize = pageSize;
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _repository.fetchNotifications(
        customerId: _customerId!,
        accessToken: _accessToken!,
        page: 1,
        limit: _pageSize,
      );

      _notifications
        ..clear()
        ..addAll(_sortByNewest(result.items));

      _hasMore = result.hasMore;
      _currentPage = 1;

      await _repository.saveCachedNotifications(_customerId!, _notifications);
      await refreshUnreadCount(silent: true);
    } on UnauthorizedException {
      _errorMessage = 'Session expired';
      clearSession();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      final cached = await _repository.loadCachedNotifications(_customerId!);
      if (cached.isNotEmpty) {
        _notifications
          ..clear()
          ..addAll(_sortByNewest(cached));
        _hasMore = false;
        await refreshUnreadCount(silent: true);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!hasSession || _isLoading || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final result = await _repository.fetchNotifications(
        customerId: _customerId!,
        accessToken: _accessToken!,
        page: nextPage,
        limit: _pageSize,
      );

      final existingIds = _notifications.map((n) => n.id).toSet();
      final merged = <NotificationModel>[
        ..._notifications,
        ...result.items.where((item) => !existingIds.contains(item.id)),
      ];

      _notifications
        ..clear()
        ..addAll(_sortByNewest(merged));

      _currentPage = nextPage;
      _hasMore = result.hasMore;

      await _repository.saveCachedNotifications(_customerId!, _notifications);
    } on UnauthorizedException {
      _errorMessage = 'Session expired';
      clearSession();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshUnreadCount({bool silent = false}) async {
    if (!hasSession) return;

    if (!silent) {
      notifyListeners();
    }

    try {
      final remote = await _repository.fetchUnreadCount(
        customerId: _customerId!,
        accessToken: _accessToken!,
      );
      _unreadCount = remote;
      await _repository.saveCachedUnreadCount(_customerId!, remote);
    } on UnauthorizedException {
      _errorMessage = 'Session expired';
      clearSession();
      rethrow;
    } catch (_) {
      final cached = await _repository.loadCachedUnreadCount(_customerId!);
      if (cached != null) _unreadCount = cached;
    } finally {
      if (!silent) notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (!hasSession) return;

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) return;

    try {
      final updated = await _repository.markAsRead(
        notificationId: notificationId,
        accessToken: _accessToken!,
      );

      _notifications[index] = updated;
      _unreadCount = _notifications.where((n) => !n.isRead).length;

      await _repository.saveCachedNotifications(_customerId!, _notifications);
      await _repository.saveCachedUnreadCount(_customerId!, _unreadCount);
      notifyListeners();
    } on UnauthorizedException {
      _errorMessage = 'Session expired';
      clearSession();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (!hasSession) return;

    try {
      await _repository.markAllAsRead(
        customerId: _customerId!,
        accessToken: _accessToken!,
      );

      _notifications.replaceRange(
        0,
        _notifications.length,
        _notifications.map((n) => n.copyWith(isRead: true, readAt: DateTime.now())).toList(),
      );

      _unreadCount = 0;
      await _repository.saveCachedNotifications(_customerId!, _notifications);
      await _repository.saveCachedUnreadCount(_customerId!, 0);
      notifyListeners();
    } on UnauthorizedException {
      _errorMessage = 'Session expired';
      clearSession();
      rethrow;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void upsertForegroundNotification(NotificationModel notification) {
    final index = _notifications.indexWhere((n) => n.id == notification.id);
    if (index == -1) {
      _notifications.insert(0, notification);
    } else {
      _notifications[index] = notification;
    }

    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();

    if (_customerId != null) {
      unawaited(_repository.saveCachedNotifications(_customerId!, _notifications));
      unawaited(_repository.saveCachedUnreadCount(_customerId!, _unreadCount));
    }
  }

  List<NotificationModel> _sortByNewest(List<NotificationModel> items) {
    final sorted = [...items];
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }
}