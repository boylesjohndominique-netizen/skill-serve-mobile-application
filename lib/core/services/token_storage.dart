import 'package:shared_preferences/shared_preferences.dart';

/// Temporary token store for the API integration scaffold.
/// Replace with platform secure storage before enabling live API mode in production.
class TokenStorage {
  TokenStorage._();

  static const accessTokenKey = 'skillserve.api.accessToken';
  static const refreshTokenKey = 'skillserve.api.refreshToken';
  static const expiresAtKey = 'skillserve.api.expiresAt';

  static Future<String?> readAccessToken() async =>
      (await SharedPreferences.getInstance()).getString(accessTokenKey);

  static Future<void> save(
      {String? accessToken, String? refreshToken, String? expiresAt}) async {
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null) await prefs.setString(accessTokenKey, accessToken);
    if (refreshToken != null) {
      await prefs.setString(refreshTokenKey, refreshToken);
    }
    if (expiresAt != null) await prefs.setString(expiresAtKey, expiresAt);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(accessTokenKey);
    await prefs.remove(refreshTokenKey);
    await prefs.remove(expiresAtKey);
  }
}
