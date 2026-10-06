import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skillserve_mobile/features/settings/controllers/preferences_controller.dart';
import 'package:skillserve_mobile/features/settings/models/user_preferences.dart';
import 'package:skillserve_mobile/features/settings/services/preferences_service.dart';

/// Stands in for the API so the controller's sync and rollback behaviour can
/// be exercised without a server.
class _FakePreferencesService implements PreferencesService {
  UserPreferences stored;
  bool failWrites;
  bool failReads;
  int saveCalls = 0;
  Map<String, dynamic>? lastChanges;

  _FakePreferencesService({
    this.stored = UserPreferences.defaults,
    this.failWrites = false,
    this.failReads = false,
  });

  @override
  Future<UserPreferences> fetch() async {
    if (failReads) throw Exception('offline');
    return stored;
  }

  @override
  Future<UserPreferences> save(Map<String, dynamic> changes) async {
    saveCalls++;
    lastChanges = changes;
    if (failWrites) throw Exception('offline');
    stored = UserPreferences.fromJson({...stored.toJson(), ...changes});
    return stored;
  }
}

Future<PreferencesController> _signedInController(
    _FakePreferencesService service) async {
  final controller = PreferencesController(service: service);
  await controller.initialize();
  await controller.onAuthChanged(signedIn: true);
  return controller;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('signing in pulls the account settings from the server', () async {
    final service = _FakePreferencesService(
      stored: const UserPreferences(
          announcementNotifications: false, theme: ThemeMode.dark),
    );

    final controller = await _signedInController(service);

    expect(controller.announcementNotifications, isFalse);
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.isLoading, isFalse);
  });

  test('a saved change is sent as a partial update', () async {
    final service = _FakePreferencesService();
    final controller = await _signedInController(service);

    final saved = await controller.setPrivateProfile(true);

    expect(saved, isTrue);
    expect(controller.privateProfile, isTrue);
    expect(service.lastChanges, {'private_profile': true});
  });

  test('a failed save rolls the switch back and explains why', () async {
    final service = _FakePreferencesService(failWrites: true);
    final controller = await _signedInController(service);

    final saved = await controller.setBookingNotifications(false);

    expect(saved, isFalse);
    expect(controller.bookingNotifications, isTrue,
        reason: 'the switch must not claim a change that was not stored');
    expect(controller.errorMessage, isNotNull);
  });

  test('settings are cached so the next launch starts with them', () async {
    final service = _FakePreferencesService();
    final controller = await _signedInController(service);
    await controller.setThemeMode(ThemeMode.dark);

    // A fresh launch, before any network call.
    final relaunched = PreferencesController(service: _FakePreferencesService());
    await relaunched.initialize();

    expect(relaunched.themeMode, ThemeMode.dark);
  });

  test('an unreachable server keeps the cached settings usable', () async {
    final service = _FakePreferencesService();
    final controller = await _signedInController(service);
    await controller.setThemeMode(ThemeMode.dark);

    final offline = PreferencesController(
        service: _FakePreferencesService(failReads: true));
    await offline.initialize();
    await offline.onAuthChanged(signedIn: true);

    expect(offline.themeMode, ThemeMode.dark);
    expect(offline.errorMessage, isNotNull);
  });

  test('signing out drops the settings so the next account starts clean',
      () async {
    final service = _FakePreferencesService();
    final controller = await _signedInController(service);
    await controller.setThemeMode(ThemeMode.dark);

    await controller.onAuthChanged(signedIn: false);

    expect(controller.themeMode, ThemeMode.system);
    expect(controller.privateProfile, isFalse);
  });

  test('setting a value it already has does not call the server', () async {
    final service = _FakePreferencesService();
    final controller = await _signedInController(service);

    await controller.setBookingNotifications(true);

    expect(service.saveCalls, 0);
  });

  test('toggling dark mode moves between light and dark', () async {
    final service = _FakePreferencesService();
    final controller = await _signedInController(service);

    await controller.toggleDarkMode();
    expect(controller.themeMode, ThemeMode.dark);
    expect(controller.isDarkMode, isTrue);

    await controller.toggleDarkMode();
    expect(controller.themeMode, ThemeMode.light);
  });

  test('an auth change notifies no one synchronously', () async {
    // The provider calls this from its `update`, which runs during a build:
    // notifying there would throw "tried to modify a provider while the
    // widget tree was building".
    final controller = PreferencesController(service: _FakePreferencesService());
    var notified = false;
    controller.addListener(() => notified = true);

    final pending = controller.onAuthChanged(signedIn: true);

    expect(notified, isFalse);
    await pending;
    expect(notified, isTrue, reason: 'it must still run, just not inline');
  });

  test('the wire format round-trips every setting', () {
    const values = UserPreferences(
      bookingNotifications: false,
      serviceNotifications: false,
      messageNotifications: false,
      announcementNotifications: false,
      privateProfile: true,
      activityPersonalization: false,
      reduceMotion: true,
      theme: ThemeMode.light,
    );

    expect(UserPreferences.fromJson(values.toJson()), values);
  });
}
