import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

/// Small pill badge for statuses (booking status, verification status, etc.)
/// Mirrors the color logic used on the Admin Web Application for consistency.
/// Active/in-progress statuses get a subtle pulse animation.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusTone tone;

  const StatusBadge({super.key, required this.label, required this.tone});

  factory StatusBadge.fromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'active':
      case 'verified':
      case 'approved':
      case 'completed':
        return StatusBadge(label: _labelize(status), tone: StatusTone.success);
      case 'pending':
        return StatusBadge(label: _labelize(status), tone: StatusTone.warning);
      case 'cancelled':
      case 'rejected':
      case 'disputed':
        return StatusBadge(label: _labelize(status), tone: StatusTone.error);
      case 'inprogress':
      case 'in_progress':
        return const StatusBadge(label: 'In Progress', tone: StatusTone.info);
      default:
        return StatusBadge(label: _labelize(status), tone: StatusTone.neutral);
    }
  }

  static String _labelize(String s) =>
      s.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');

  bool get _shouldPulse => tone == StatusTone.info || tone == StatusTone.warning;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(tone);
    Widget badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: colors.$2, fontWeight: FontWeight.w600),
      ),
    );

    if (_shouldPulse) {
      badge = badge
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end: 1.05,
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
          );
    }

    return badge;
  }

  (Color, Color) _colorsFor(StatusTone tone) {
    switch (tone) {
      case StatusTone.success:
        return (AppColors.successBg, AppColors.success);
      case StatusTone.warning:
        return (AppColors.warningBg, AppColors.warning);
      case StatusTone.error:
        return (AppColors.errorBg, AppColors.error);
      case StatusTone.info:
        return (AppColors.infoBg, AppColors.info);
      case StatusTone.neutral:
        return (AppColors.neutral50, AppColors.neutral400);
    }
  }
}

enum StatusTone { success, warning, error, info, neutral }
