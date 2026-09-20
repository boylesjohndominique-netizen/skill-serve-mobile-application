import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_preferences.dart';
import '../services/preferences_service.dart';

/// The account's settings, and the single source of truth for them.
///
/// Settings live on the server so they follow the account to any device.
/// The device also keeps a cache, which is what the app reads at launch:
/// that way the correct theme is applied on the first frame and the
/// switches stay usable offline. The server copy wins as soon as it
/// arrives.
///
/// Writes are optimistic — the switch moves immediately, then the change is
/// sent. If the request fails the value is rolled back and [errorMessage]
/// explains why, so a switch never lies about what was saved.
class PreferencesController extends ChangeNotifier {
  PreferencesController({PreferencesService? service})
      : _service = service ?? PreferencesService();

  final PreferencesService _service;

  static const _cacheKey = 'skillserve.preferences';

  UserPreferences _values = UserPreferences.defaults;
  bool _loading = false;
  bool _saving = false;
  String? errorMessage;
  bool _signedIn = false;

  UserPreferences get values => _values;

  /// True while the first server read is in flight and no cached values are
  /// available yet, so screens can show a skeleton instead of defaults.
  bool get isLoading => _loading;

  /// True while a change is being saved.
  bool get isSaving => _saving;

  bool get bookingNotifications => _values.bookingNotifications;
  bool get serviceNotifications => _values.serviceNotifications;
  bool get messageNotifications => _values.messageNotifications;
  bool get announcementNotifications => _values.announcementNotifications;
  bool get privateProfile => _values.privateProfile;
  bool get activityPersonalization => _values.activityPersonalization;
  bool get reduceMotion => _values.reduceMotion;
  ThemeMode get themeMode => _values.theme;
  bool get isDarkMode => _values.theme == ThemeMode.dark;

  /// Reads the cached settings so the app starts with the user's own theme
  /// rather than flashing the default one.
  Future<void> initialize() async {
    final cached = await _readCache();
    if (cached != null) {
      _values = cached;
      notifyListeners();
    }
  }

  /// Called when the session changes. Signing in pulls the account's
  /// settings; signing out drops them so the next account does not inherit
  /// the previous user's choices.
  ///
  /// This runs from the provider's `update`, i.e. during a build, so it
  /// must not notify listeners synchronously — everything that does is
  /// deferred past the current frame.
  Future<void> onAuthChanged({required bool signedIn}) async {
    if (signedIn == _signedIn) return;
    _signedIn = signedIn;

    await Future<void>.delayed(Duration.zero);

    if (!signedIn) {
      _values = UserPreferences.defaults;
      errorMessage = null;
      await _clearCache();
      notifyListeners();
      return;
    }

    await refresh();
  }

  /// Pulls the account's settings from the server.
  Future<void> refresh() async {
    if (!_signedIn) return;
    _loading = true;
    errorMessage = null;
    notifyListeners();
    try {
      _values = await _service.fetch();
      await _writeCache(_values);
    } catch (_) {
      // Offline or the server is unreachable: the cached values stay in
      // effect, so the screens remain usable.
      errorMessage = 'Showing your saved settings — we could not reach the server.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> setBookingNotifications(bool value) =>
      _apply(_values.copyWith(bookingNotifications: value),
          {'booking_notifications': value});

  Future<bool> setServiceNotifications(bool value) =>
      _apply(_values.copyWith(serviceNotifications: value),
          {'service_notifications': value});

  Future<bool> setMessageNotifications(bool value) =>
      _apply(_values.copyWith(messageNotifications: value),
          {'message_notifications': value});

  Future<bool> setAnnouncementNotifications(bool value) =>
      _apply(_values.copyWith(announcementNotifications: value),
          {'announcement_notifications': value});

  Future<bool> setPrivateProfile(bool value) =>
      _apply(_values.copyWith(privateProfile: value),
          {'private_profile': value});

  Future<bool> setActivityPersonalization(bool value) =>
      _apply(_values.copyWith(activityPersonalization: value),
          {'activity_personalization': value});

  Future<bool> setReduceMotion(bool value) =>
      _apply(_values.copyWith(reduceMotion: value), {'reduce_motion': value});

  Future<bool> setThemeMode(ThemeMode mode) {
    final next = _values.copyWith(theme: mode);
    return _apply(next, {'theme': next.themeName});
  }

  /// Flips between light and dark, leaving "system" for an explicit choice.
  Future<bool> toggleDarkMode() =>
      setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);

  /// Moves the UI first, then persists. On failure the previous value is
  /// restored so the switch reflects what is actually stored.
  Future<bool> _apply(
      UserPreferences next, Map<String, dynamic> changes) async {
    final previous = _values;
    if (next == previous) return true;

    _values = next;
    _saving = true;
    errorMessage = null;
    notifyListeners();

    // The cache follows the optimistic value: offline changes still apply
    // on this device and are overwritten by the server on the next refresh.
    await _writeCache(next);

    if (!_signedIn) {
      _saving = false;
      notifyListeners();
      return true;
    }

    try {
      _values = await _service.save(changes);
      await _writeCache(_values);
      return true;
    } catch (_) {
      _values = previous;
      await _writeCache(previous);
      errorMessage = 'We could not save that change. Check your connection and try again.';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  Future<UserPreferences?> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return UserPreferences.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(UserPreferences values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(values.toJson()));
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
  }
}
