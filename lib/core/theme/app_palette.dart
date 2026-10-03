import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Theme-aware foreground colours: text, icons and outlines that must stay
/// readable in both light and dark mode.
///
/// The [AppColors] constants are fixed values, so a colour picked for one
/// mode can disappear in the other — lime text on a white card (1.3:1), or
/// charcoal text on a dark one (1.0:1). Read foregrounds from here instead.
extension AppPalette on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// The brand accent as a foreground (links, prices, active icons, focus
  /// outlines): deep olive on light surfaces, lime on dark ones. Lime stays
  /// right as a *fill* behind [AppColors.primary] text in both modes.
  Color get accentInk => isDarkMode ? AppColors.secondary : AppColors.secondaryInk;

  /// The tinted fill for placeholders, icon discs and soft panels.
  Color get surfaceAltColor => isDarkMode ? AppColors.surfaceAltDark : AppColors.surfaceAlt;

  Color get textPrimaryColor => isDarkMode ? AppColors.textOnDark : AppColors.textPrimary;
  Color get textSecondaryColor => isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary;
  Color get textMutedColor => isDarkMode ? AppColors.textMutedDark : AppColors.textMuted;

  /// Rating stars: bright gold vanishes on white (1.8:1), so light mode
  /// uses a deeper amber.
  Color get starColor => isDarkMode ? AppColors.star : AppColors.starOnLight;

  Color get successColor => isDarkMode ? AppColors.successOnDark : AppColors.success;
  Color get warningColor => isDarkMode ? AppColors.warningOnDark : AppColors.warning;
  Color get errorColor => isDarkMode ? AppColors.errorOnDark : AppColors.error;
  Color get infoColor => isDarkMode ? AppColors.infoOnDark : AppColors.info;
}
