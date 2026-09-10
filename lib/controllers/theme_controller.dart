import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls light / dark / system theme selection.
class ThemeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.light;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    mode = prefs.getBool('skillserve.preference.darkMode') == true
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode newMode) async {
    mode = newMode;
    await _persist();
    notifyListeners();
  }

  Future<void> toggle() async {
    mode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'skillserve.preference.darkMode', mode == ThemeMode.dark);
  }
}
