import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesController extends ChangeNotifier {
  bool bookingNotifications = true;
  bool serviceNotifications = true;
  bool messageNotifications = true;
  bool announcementNotifications = true;
  bool privateProfile = false;
  bool activityPersonalization = true;
  bool reduceMotion = false;
  bool biometricUnlock = false;

  static const _keys = {
    'bookingNotifications': 'skillserve.preference.bookingNotifications',
    'serviceNotifications': 'skillserve.preference.serviceNotifications',
    'messageNotifications': 'skillserve.preference.messageNotifications',
    'announcementNotifications':
        'skillserve.preference.announcementNotifications',
    'privateProfile': 'skillserve.preference.privateProfile',
    'activityPersonalization': 'skillserve.preference.activityPersonalization',
    'reduceMotion': 'skillserve.preference.reduceMotion',
    'biometricUnlock': 'skillserve.preference.biometricUnlock',
  };

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    bookingNotifications =
        prefs.getBool(_keys['bookingNotifications']!) ?? true;
    serviceNotifications =
        prefs.getBool(_keys['serviceNotifications']!) ?? true;
    messageNotifications =
        prefs.getBool(_keys['messageNotifications']!) ?? true;
    announcementNotifications =
        prefs.getBool(_keys['announcementNotifications']!) ?? true;
    privateProfile = prefs.getBool(_keys['privateProfile']!) ?? false;
    activityPersonalization =
        prefs.getBool(_keys['activityPersonalization']!) ?? true;
    reduceMotion = prefs.getBool(_keys['reduceMotion']!) ?? false;
    biometricUnlock = prefs.getBool(_keys['biometricUnlock']!) ?? false;
    notifyListeners();
  }

  Future<void> setBookingNotifications(bool value) =>
      _set('bookingNotifications', value, () => bookingNotifications = value);
  Future<void> setServiceNotifications(bool value) =>
      _set('serviceNotifications', value, () => serviceNotifications = value);
  Future<void> setMessageNotifications(bool value) =>
      _set('messageNotifications', value, () => messageNotifications = value);
  Future<void> setAnnouncementNotifications(bool value) => _set(
      'announcementNotifications',
      value,
      () => announcementNotifications = value);
  Future<void> setPrivateProfile(bool value) =>
      _set('privateProfile', value, () => privateProfile = value);
  Future<void> setActivityPersonalization(bool value) => _set(
      'activityPersonalization', value, () => activityPersonalization = value);
  Future<void> setReduceMotion(bool value) =>
      _set('reduceMotion', value, () => reduceMotion = value);
  Future<void> setBiometricUnlock(bool value) =>
      _set('biometricUnlock', value, () => biometricUnlock = value);

  Future<void> _set(String name, bool value, VoidCallback update) async {
    update();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keys[name]!, value);
  }
}
