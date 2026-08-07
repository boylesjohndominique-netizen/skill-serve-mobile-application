import 'package:flutter/material.dart';

/// Central color palette for SkillServe.
///
/// Refined, harmonious aesthetic balancing:
/// Soft Off-White (#F7F8F4) + Crisp White (#FFFFFF) + Rich Charcoal (#14191F) + Electric Lime (#C7F33C) + Pale Lime (#E1F2AE).
class AppColors {
  AppColors._();

  // ---- Brand Palette ----
  static const Color primary = Color(0xFF14191F); // Soft Rich Charcoal Black
  static const Color primaryLight = Color(0xFF222933);
  static const Color primaryDark = Color(0xFF0D1115);

  static const Color secondary = Color(0xFFC7F33C); // Vibrant Lime Accent
  static const Color secondaryLight = Color(0xFFD6F66B);
  static const Color secondaryDark = Color(0xFFA5CF25);
  static const Color secondarySoft = Color(0xFFE1F2AE); // Soft Pale Lime Fill
  static const Color secondaryDeep = Color(0xFF1A2600); // Deep forest green-black for text on pale lime

  static const Color accent = Color(0xFF14191F); // Balanced accent

  // ---- Light theme surfaces ----
  static const Color background = Color(0xFFF7F8F4); // Soft, gentle warm off-white
  static const Color surface = Color(0xFFFFFFFF); // Pure white card surface
  static const Color surfaceAlt = Color(0xFFEEF2E3); // Soft pale tint fill
  static const Color line = Color(0xFFE0E5D4); // Soft border divider

  // ---- Dark theme surfaces ----
  static const Color backgroundDark = Color(0xFF0F1318);
  static const Color surfaceDark = Color(0xFF1A2027);
  static const Color surfaceAltDark = Color(0xFF242C36);
  static const Color lineDark = Color(0xFF2E3742);

  // ---- Text ----
  static const Color textPrimary = Color(0xFF181C20); // Deep charcoal (easy on eyes)
  static const Color textSecondary = Color(0xFF4E545E); // Soft slate grey
  static const Color textMuted = Color(0xFF828894); // Muted grey
  static const Color textOnDark = Color(0xFFF7F8F9); // Gentle soft white on dark
  static const Color textMutedDark = Color(0xFF9DA3AF);

  // ---- Semantic ----
  static const Color success = Color(0xFF12896A);
  static const Color successBg = Color(0xFFEBF7F2);
  static const Color warning = Color(0xFF9E6D0F);
  static const Color warningBg = Color(0xFFFAF4E6);
  static const Color error = Color(0xFFD1453B);
  static const Color errorBg = Color(0xFFFBEAE9);
  static const Color info = Color(0xFF1F5F8B);
  static const Color infoBg = Color(0xFFEBF3F8);

  // ---- Neutral scale ----
  static const Color neutral50 = Color(0xFFF7F8F4);
  static const Color neutral100 = Color(0xFFE8ECD9);
  static const Color neutral200 = Color(0xFFCBD2BF);
  static const Color neutral300 = Color(0xFF949C87);
  static const Color neutral400 = Color(0xFF5E6553);
  static const Color neutral500 = Color(0xFF32362C);

  // ---- Gradients ----
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14191F), Color(0xFF222933)],
  );

  static const LinearGradient brassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC7F33C), Color(0xFFA5CF25)],
  );

  /// Rating star color — warm golden amber star.
  static const Color star = Color(0xFFF2B705);
}
