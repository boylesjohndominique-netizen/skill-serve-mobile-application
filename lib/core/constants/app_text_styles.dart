import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system for SkillServe.
///
/// Display / Headline / Title -> Space Grotesk (matches the admin web's
/// technical, distinctive display face).
/// Body / Caption / Button / Label -> Inter (matches the admin web's UI face).
/// Mono (IDs, prices, references, timestamps) -> IBM Plex Mono.
///
/// Colors are intentionally omitted from static styles so that every text
/// widget inherits the correct color from the theme's [DefaultTextStyle].
/// This ensures all text remains visible in both light and dark modes.
class AppTextStyles {
  AppTextStyles._();

  static final TextStyle _display = GoogleFonts.spaceGrotesk();
  static final TextStyle _body = GoogleFonts.inter();
  static final TextStyle _mono = GoogleFonts.ibmPlexMono();

  // ---- Display ----
  static TextStyle displayLarge = _display.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = _display.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.4,
  );

  // ---- Headline ----
  static TextStyle headlineLarge = _display.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle headlineMedium = _display.copyWith(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // ---- Title ----
  static TextStyle titleLarge = _display.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  static TextStyle titleMedium = _body.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  // ---- Body ----
  static TextStyle bodyLarge = _body.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodyMedium = _body.copyWith(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static TextStyle bodySmall = _body.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // ---- Caption / Label ----
  static TextStyle caption = _body.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  static TextStyle overline = _body.copyWith(
    fontSize: 10.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.4,
  );

  static TextStyle label = _body.copyWith(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
  );

  // ---- Button ----
  static TextStyle button = _body.copyWith(
    fontSize: 14.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  // ---- Mono (IBM Plex Mono — IDs, prices, references, timestamps) ----
  static TextStyle monoSm = _mono.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle monoMd = _mono.copyWith(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle monoLg = _mono.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle monoDisplay = _mono.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
  );

  // ---- Eyebrow (11px mono, uppercase, wide tracking, muted) ----
  static TextStyle eyebrow = _mono.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.8,
    height: 1.4,
  );

  /// Returns a dark-theme-adjusted copy of any style in this system.
  static TextStyle onDark(TextStyle style) =>
      style.copyWith(color: AppColors.textOnDark);
}
