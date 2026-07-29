import 'package:flutter/material.dart';

/// Central color palette for SkillLink.
///
/// Visual identity is inherited from the Admin Web Application:
/// Ink Navy (structure/trust) + Brass (accent/action) + Warm Slate (canvas).
/// Semantic colors (success/warning/error) and a dark theme variant are
/// layered on top for mobile-specific needs.
class AppColors {
  AppColors._();

  // ---- Brand ----
  static const Color primary = Color(0xFF101828); // Ink Navy
  static const Color primaryLight = Color(0xFF333B52);
  static const Color primaryDark = Color(0xFF0A0F1C);

  static const Color secondary = Color(0xFFC9852E); // Brass
  static const Color secondaryLight = Color(0xFFE3AD50);
  static const Color secondaryDark = Color(0xFFA66B22);

  static const Color accent = Color(0xFF2F6690); // Muted teal-blue, complements brass without breaking the 2-hue identity

  // ---- Light theme surfaces ----
  static const Color background = Color(0xFFF5F4F1); // Warm Slate canvas
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF3F4F6);
  static const Color line = Color(0xFFE6E4DE);

  // ---- Dark theme surfaces ----
  static const Color backgroundDark = Color(0xFF0A0F1C);
  static const Color surfaceDark = Color(0xFF161D30);
  static const Color surfaceAltDark = Color(0xFF1F273D);
  static const Color lineDark = Color(0xFF2A3350);

  // ---- Text ----
  static const Color textPrimary = Color(0xFF101828);
  static const Color textSecondary = Color(0xFF475467);
  static const Color textMuted = Color(0xFF8A8F98);
  static const Color textOnDark = Color(0xFFF5F4F1);
  static const Color textMutedDark = Color(0xFF9AA3B8);

  // ---- Semantic ----
  static const Color success = Color(0xFF12896A);
  static const Color successBg = Color(0xFFE7F5F0);
  static const Color warning = Color(0xFFB7791F);
  static const Color warningBg = Color(0xFFFBF3E7);
  static const Color error = Color(0xFFD1453B);
  static const Color errorBg = Color(0xFFFBEAE9);
  static const Color info = Color(0xFF2F6690);
  static const Color infoBg = Color(0xFFEAF2F7);

  // ---- Neutral scale ----
  static const Color neutral50 = Color(0xFFF3F4F6);
  static const Color neutral100 = Color(0xFFE4E7EB);
  static const Color neutral200 = Color(0xFFC3C9D3);
  static const Color neutral300 = Color(0xFF8F97A8);
  static const Color neutral400 = Color(0xFF5B637A);
  static const Color neutral500 = Color(0xFF333B52);

  // ---- Gradients ----
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF101828), Color(0xFF1F273D)],
  );

  static const LinearGradient brassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD69B3B), Color(0xFFA66B22)],
  );

  /// Rating star color — kept distinct from brass so 5-star ratings read clearly.
  static const Color star = Color(0xFFF2B705);
}
