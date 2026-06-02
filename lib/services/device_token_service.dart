import 'package:shared_preferences/shared_preferences.dart';

class DeviceTokenApi {
  DeviceTokenApi({
    this.registerEndpoint,
    this.unregisterEndpoint,
  });

  final String? registerEndpoint;
  final String? unregisterEndpoint;

  static const String _cacheTokenKey = 'fcm_device_token_cache';
  static const String _cacheCustomerKey = 'fcm_device_customer_cache';
  static const String _cachePlatformKey = 'fcm_device_platform_cache';

  Future<void> registerToken({
    required String customerId,
    required String token,
    required String platform,
    String? accessToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Fallback local si no hi ha endpoint backend definit al projecte local.
    if (registerEndpoint == null || registerEndpoint!.isEmpty) {
      await prefs.setString(_cacheTokenKey, token);
      await prefs.setString(_cacheCustomerKey, customerId);
      await prefs.setString(_cachePlatformKey, platform);
      return;
    }

    // TODO: quan existeixi l'endpoint real, fer POST al backend:
    // POST {registerEndpoint}
    // body: { customer_id, token, platform, active: true }
    // headers: Authorization: Bearer <accessToken>
    //
    // De moment guardem fallback local per no trencar l'app.
    await prefs.setString(_cacheTokenKey, token);
    await prefs.setString(_cacheCustomerKey, customerId);
    await prefs.setString(_cachePlatformKey, platform);
  }

  Future<void> unregisterToken({
    required String token,
    String? accessToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (unregisterEndpoint == null || unregisterEndpoint!.isEmpty) {
      final cached = prefs.getString(_cacheTokenKey);
      if (cached == token) {
        await prefs.remove(_cacheTokenKey);
        await prefs.remove(_cacheCustomerKey);
        await prefs.remove(_cachePlatformKey);
      }
      return;
    }

    // TODO: quan existeixi l'endpoint real, fer request al backend.
    final cached = prefs.getString(_cacheTokenKey);
    if (cached == token) {
      await prefs.remove(_cacheTokenKey);
      await prefs.remove(_cacheCustomerKey);
      await prefs.remove(_cachePlatformKey);
    }
  }
}