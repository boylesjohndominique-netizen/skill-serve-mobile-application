import 'package:flutter/animation.dart';

/// Central animation constants used across the entire app.
/// Every widget and screen pulls from these values so motion feels
/// coherent — nothing is ad-hoc.
class AppAnimations {
  AppAnimations._();

  // ── Durations ──────────────────────────────────────────────
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration md = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 350);

  // ── Curves ─────────────────────────────────────────────────
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve springCurve = Curves.easeOutBack;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve sharpCurve = Curves.easeInOutCubicEmphasized;

  // ── Offsets (for slide animations) ─────────────────────────
  static const double slideUpOffset = 0.08;
  static const double slideRightOffset = 0.06;

  // ── Press scale ────────────────────────────────────────────
  static const double pressScale = 0.97;
  static const double cardPressScale = 0.98;

  // ── Stagger delay calculator ───────────────────────────────
  /// Returns incremental delay for item at [index] in a staggered list.
  /// Cap at 8 to avoid excessive delays for long lists.
  static Duration staggerDelay(int index, {Duration base = const Duration(milliseconds: 60)}) {
    final capped = index.clamp(0, 8);
    return base * capped;
  }
}
