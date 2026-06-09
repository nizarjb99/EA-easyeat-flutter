import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// Registers and unregisters FCM device tokens with the backend.
///
/// The endpoint is resolved from [AppConstants.deviceTokensUrl].  When the
/// constant is empty (e.g. during local development) the token is cached in
/// [SharedPreferences] only, so the rest of the app still works without a
/// real backend endpoint.
class DeviceTokenApi {
  DeviceTokenApi({
    http.Client? httpClient,
    String? registerEndpoint,
    String? unregisterEndpoint,
  })  : _client = httpClient ?? http.Client(),
  // Accept an explicit override, otherwise use the constant.
        _registerEndpoint = registerEndpoint ??
            (AppConstants.baseUrl.isNotEmpty
                ? '${AppConstants.baseUrl}/register'
                : ''),
        _unregisterEndpoint = unregisterEndpoint ??
            (AppConstants.baseUrl.isNotEmpty
                ? '${AppConstants.baseUrl}/unregister'
                : '');

  final http.Client _client;
  final String _registerEndpoint;
  final String _unregisterEndpoint;

  // SharedPreferences keys – used as a local cache / fallback.
  static const String _cacheTokenKey = 'fcm_device_token_cache';
  static const String _cacheCustomerKey = 'fcm_device_customer_cache';
  static const String _cachePlatformKey = 'fcm_device_platform_cache';

  // ──────────────────────────────────────────────────────────────────────────

  /// Sends the FCM [token] to the backend so the server can target this
  /// device.  Also caches the token locally for deduplication.
  Future<void> registerToken({
    required String customerId,
    required String token,
    required String platform,
    String? accessToken,
  }) async {
    // Persist locally first – this is used for deduplication on
    // unregister and survives backend failures.
    await _cacheLocally(token: token, customerId: customerId, platform: platform);

    if (_registerEndpoint.isEmpty) {
      debugPrint('[DeviceTokenApi] No register endpoint configured – '
          'token cached locally only.');
      return;
    }

    try {
      final response = await _client
          .post(
        Uri.parse(_registerEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(<String, dynamic>{
          'customer_id': customerId,
          'token': token,
          'platform': platform,
          'active': true,
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[DeviceTokenApi] Token registered successfully.');
      } else {
        debugPrint('[DeviceTokenApi] Registration failed '
            '(${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      // Non-fatal: the app works without a registered token; the user simply
      // won't receive push notifications until the next successful register.
      debugPrint('[DeviceTokenApi] Error registering token: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────

  /// Removes the FCM [token] from the backend so this device no longer
  /// receives notifications for the associated user.
  Future<void> unregisterToken({
    required String token,
    String? accessToken,
  }) async {
    if (_unregisterEndpoint.isEmpty) {
      debugPrint('[DeviceTokenApi] No unregister endpoint configured – '
          'token removed from local cache only.');
      await _removeCachedToken(token);
      return;
    }

    try {
      final response = await _client
          .post(
        Uri.parse(_unregisterEndpoint),
        headers: <String, String>{
          'Content-Type': 'application/json',
          if (accessToken != null && accessToken.isNotEmpty)
            'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(<String, dynamic>{
          'token': token,
          'active': false,
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[DeviceTokenApi] Token unregistered successfully.');
        await _removeCachedToken(token);
      } else {
        debugPrint('[DeviceTokenApi] Unregister failed '
            '(${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[DeviceTokenApi] Error unregistering token: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Cached-token helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the locally cached FCM token, or `null` if none has been saved.
  Future<String?> getCachedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cacheTokenKey);
  }

  Future<void> _cacheLocally({
    required String token,
    required String customerId,
    required String platform,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheTokenKey, token);
    await prefs.setString(_cacheCustomerKey, customerId);
    await prefs.setString(_cachePlatformKey, platform);
  }

  Future<void> _removeCachedToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheTokenKey);
    if (cached == token) {
      await prefs.remove(_cacheTokenKey);
      await prefs.remove(_cacheCustomerKey);
      await prefs.remove(_cachePlatformKey);
    }
  }
}