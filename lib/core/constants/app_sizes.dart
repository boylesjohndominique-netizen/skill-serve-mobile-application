import 'package:flutter/material.dart';

/// Shared spacing, radius, elevation, and shadow constants — keep every
/// screen visually consistent without hardcoding magic numbers.
class AppSizes {
  AppSizes._();

  // Spacing
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double xxxl = 40;

  // Radius
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 22;
  static const double radiusPill = 999;

  // Icon sizes
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 26;

  // Elevation-equivalent shadow blur
  static const double shadowBlur = 18;

  // Page horizontal padding
  static const double pageHPad = 20;

  // ── Shadow presets (light mode) ──────────────────────────
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // ── Shadow presets (dark mode — more subtle) ─────────────
  static List<BoxShadow> get shadowSmDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMdDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowLgDark => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Returns the appropriate shadow for current brightness.
  static List<BoxShadow> shadowFor(BuildContext context, {ShadowLevel level = ShadowLevel.sm}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (level) {
      case ShadowLevel.sm:
        return isDark ? shadowSmDark : shadowSm;
      case ShadowLevel.md:
        return isDark ? shadowMdDark : shadowMd;
      case ShadowLevel.lg:
        return isDark ? shadowLgDark : shadowLg;
    }
  }
}

enum ShadowLevel { sm, md, lg }
