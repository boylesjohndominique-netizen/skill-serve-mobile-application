import 'package:flutter/material.dart';

/// Central color palette for SkillServe.
///
/// Soft, harmonious pastel concept palette:
///   primary      #1C2128 — gentle deep charcoal (structure, primary text)
///   secondary    #C7F33C — soft pastel lime accent (active CTAs, highlights)
///   secondarySoft#E1F2AE — pale pastel lime tint (chip fills, soft badges)
///   secondaryLight#EFF6D3 — ultra-soft lime surface tint
///   canvas       #F8F9F3 — soft creamy off-white canvas
///   surface      #FFFFFF — crisp white card surface
///   line         #E2E7D7 — gentle border line
class AppColors {
  AppColors._();

  // ---- Brand Palette (Soft Pastel Theme) ----
  static const Color primary = Color(0xFF1C2128); // Soft Charcoal Black
  static const Color primaryLight = Color(0xFF2B323D);
  static const Color primaryDark = Color(0xFF12161B);

  static const Color secondary = Color(0xFFC7F33C); // Soft Pastel Lime Accent
  static const Color secondaryLight = Color(0xFFEFF6D3); // Ultra-soft lime surface tint
  static const Color secondaryDark = Color(0xFFA5CF25);
  static const Color secondarySoft = Color(0xFFE1F2AE); // Soft Pale Lime Fill
  static const Color secondaryDeep = Color(0xFF1E2800); // Deep forest green-black for text on pale lime

  static const Color accent = Color(0xFFC7F33C); // Soft lime accent

  // ---- Light theme surfaces ----
  static const Color background = Color(0xFFF8F9F3); // Soft creamy off-white canvas
  static const Color surface = Color(0xFFFFFFFF); // Pure white card surface
  static const Color surfaceAlt = Color(0xFFEEF3E4); // Subtle pastel lime surface
  static const Color line = Color(0xFFE2E7D7); // Gentle border divider line

  // ---- Dark theme surfaces ----
  static const Color backgroundDark = Color(0xFF0F1318);
  static const Color surfaceDark = Color(0xFF1A2027);
  static const Color surfaceAltDark = Color(0xFF242C36);
  static const Color lineDark = Color(0xFF2E3742);

  // ---- Text ----
  static const Color textPrimary = Color(0xFF1C2128); // Gentle deep charcoal
  static const Color textSecondary = Color(0xFF575E6A); // Soft slate grey
  static const Color textMuted = Color(0xFF8C939E); // Muted pastel grey
  static const Color textOnDark = Color(0xFFF5F7FA); // Soft warm white on dark
  static const Color textMutedDark = Color(0xFF9DA3AF);

  // ---- Semantic ----
  static const Color success = Color(0xFF12896A); // emerald
  static const Color successBg = Color(0xFFEBF7F2);
  static const Color warning = Color(0xFF9E6D0F); // warm amber
  static const Color warningBg = Color(0xFFFAF4E6);
  static const Color error = Color(0xFFD1453B); // soft red
  static const Color errorBg = Color(0xFFFBEAE9);
  static const Color info = Color(0xFF1F5F8B); // soft blue
  static const Color infoBg = Color(0xFFEBF3F8);

  // ---- Neutral scale ----
  static const Color neutral50 = Color(0xFFF8F9F3);
  static const Color neutral100 = Color(0xFFE8ECD9);
  static const Color neutral200 = Color(0xFFCBD2BF);
  static const Color neutral300 = Color(0xFF949C87);
  static const Color neutral400 = Color(0xFF5E6553);
  static const Color neutral500 = Color(0xFF32362C);

  // ---- Gradients ----
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C2128), Color(0xFF2B323D)],
  );

  static const LinearGradient brassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC7F33C), Color(0xFFA5CF25)],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9F3)],
  );

  /// Rating star color — warm golden amber star.
  static const Color star = Color(0xFFF2B705);
}
