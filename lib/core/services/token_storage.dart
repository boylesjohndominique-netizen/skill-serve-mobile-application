import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The session's API tokens, kept in platform secure storage — the iOS
/// Keychain and an Android Keystore-backed cipher — so they cannot be read
/// off a rooted or jailbroken device the way plain SharedPreferences can.
/// The long-lived refresh token keeps a user signed in until they sign out,
/// which is why it matters.
///
/// Earlier builds stored the tokens in SharedPreferences. The first read
/// moves them here and deletes the old copies, so updating the app does not
/// sign anyone out. The cached account itself stays in SharedPreferences: it
/// is not a secret.
class TokenStorage {
  TokenStorage._();

  static const accessTokenKey = 'skillserve.api.accessToken';
  static const refreshTokenKey = 'skillserve.api.refreshToken';
  static const expiresAtKey = 'skillserve.api.expiresAt';

  /// The narrow token the background notification check uses; it can only
  /// read pending notifications. Cleared with the rest on sign-out.
  static const backgroundTokenKey = 'skillserve.api.backgroundToken';
  static const _keys = [accessTokenKey, refreshTokenKey, expiresAtKey, backgroundTokenKey];

  // Readable after the first unlock following a reboot, so a token refresh
  // started while the phone is locked still works.
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static Future<void>? _migration;

  static Future<String?> readAccessToken() => _read(accessTokenKey);

  /// The long-lived token that renews the access token. Present for as long
  /// as the user stays signed in.
  static Future<String?> readRefreshToken() => _read(refreshTokenKey);

  static Future<String?> readBackgroundToken() => _read(backgroundTokenKey);

  static Future<void> saveBackgroundToken(String token) async {
    await _migrateLegacy();
    await _storage.write(key: backgroundTokenKey, value: token);
  }

  /// Drops a background token the server refused, so the next sign-in
  /// ([BackgroundNotifications.enable]) asks for a new one.
  static Future<void> clearBackgroundToken() async {
    await _migrateLegacy();
    await _storage.delete(key: backgroundTokenKey);
  }

  static Future<void> save(
      {String? accessToken, String? refreshToken, String? expiresAt}) async {
    await _migrateLegacy();
    if (accessToken != null) await _storage.write(key: accessTokenKey, value: accessToken);
    if (refreshToken != null) await _storage.write(key: refreshTokenKey, value: refreshToken);
    if (expiresAt != null) await _storage.write(key: expiresAtKey, value: expiresAt);
  }

  static Future<void> clear() async {
    await _migrateLegacy();
    for (final key in _keys) {
      await _storage.delete(key: key);
    }
  }

  static Future<String?> _read(String key) async {
    await _migrateLegacy();
    try {
      return await _storage.read(key: key);
    } catch (_) {
      // Unreadable storage (e.g. a keystore restored from another device's
      // backup) cannot hold a usable session; treat it as signed out.
      return null;
    }
  }

  /// Runs once per launch: copies any tokens an older build left in
  /// SharedPreferences into secure storage, then removes them.
  static Future<void> _migrateLegacy() => _migration ??= () async {
        final prefs = await SharedPreferences.getInstance();
        for (final key in _keys) {
          final legacy = prefs.getString(key);
          if (legacy == null) continue;
          try {
            if (await _storage.read(key: key) == null) {
              await _storage.write(key: key, value: legacy);
            }
          } catch (_) {
            // Leave the old copy in place if secure storage is unavailable;
            // the next launch tries again.
            continue;
          }
          await prefs.remove(key);
        }
      }();

  /// Lets tests start each case from fresh storage.
  static void resetForTesting() => _migration = null;
}
