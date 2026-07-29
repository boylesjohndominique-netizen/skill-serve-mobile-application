import 'package:flutter/material.dart';

/// Controls light / dark / system theme selection.
/// Placeholder persistence — wire to SharedPreferences when ready.
class ThemeController extends ChangeNotifier {
  ThemeMode mode = ThemeMode.light;

  void setMode(ThemeMode newMode) {
    mode = newMode;
    notifyListeners();
  }

  void toggle() {
    mode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
