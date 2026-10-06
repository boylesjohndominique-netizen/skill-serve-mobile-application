import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Where sign-up's National ID scan had got to, kept on the phone so it
/// survives Android closing the app while the camera is open — which
/// low-memory phones do, and which otherwise drops the user back at the start
/// of the app with the sign-up gone.
///
/// Only the paths of the two photos are kept, never what was read off them:
/// the card is read again when the scan is resumed. Progress older than
/// [maxAge] is ignored, so an abandoned sign-up does not reopen days later.
///
/// Best effort: if the phone's storage cannot be used, sign-up carries on as
/// before, only without surviving a restart.
class SignUpScanStore {
  SignUpScanStore._();

  static const _key = 'skillserve.signUp.idScan';
  static const maxAge = Duration(hours: 1);

  /// Sign-up is scanning the card: a restart from here returns to it. The
  /// photos already taken are kept.
  static Future<void> start() async {
    final current = await load() ?? const SignUpScan();
    await _write(current);
  }

  /// A side of the card was photographed at [path].
  static Future<void> saveSide(String type, String path) async {
    final current = await load() ?? const SignUpScan();
    await _write(current.withSide(type, path));
  }

  /// The scan in progress, or null when there is none (or it is too old).
  static Future<SignUpScan?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final startedAt = DateTime.tryParse(json['started_at'] as String? ?? '');
      if (startedAt == null || DateTime.now().difference(startedAt) > maxAge) {
        await prefs.remove(_key);
        return null;
      }
      return SignUpScan(sides: Map<String, String>.from(json['sides'] as Map? ?? const {}));
    } catch (_) {
      await clear();
      return null;
    }
  }

  /// The sign-up finished or was abandoned.
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }

  static Future<void> _write(SignUpScan scan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode({
        'started_at': DateTime.now().toIso8601String(),
        'sides': scan.sides,
      }));
    } catch (_) {}
  }
}

/// The photo path of each side taken so far, keyed by document type.
class SignUpScan {
  const SignUpScan({this.sides = const {}});

  final Map<String, String> sides;

  String? path(String type) => sides[type];

  SignUpScan withSide(String type, String path) => SignUpScan(sides: {...sides, type: path});
}
