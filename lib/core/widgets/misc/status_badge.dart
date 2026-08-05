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

  /// Maps every status enum (Section 4) to the admin console's Badge colors
  /// (Section 10): emerald (success), brass (pending), blue (progress),
  /// orange (warning), red (failure/blocked), neutral (hidden/closed).
  factory StatusBadge.fromStatus(String status) {
    final s = status.toLowerCase().replaceAll(' ', '_');
    switch (s) {
      // Emerald — success / verified / paid / completed / sent
      case 'active':
      case 'verified':
      case 'approved':
      case 'completed':
      case 'visible':
      case 'sent':
      case 'paid':
        return StatusBadge(label: _labelize(s), tone: StatusTone.success);
      // Brass — pending / confirmed / resubmission
      case 'pending':
      case 'confirmed':
      case 'resubmission_requested':
      case 'resubmit':
        return StatusBadge(label: _labelize(s), tone: StatusTone.warning);
      // Blue — in progress / investigating
      case 'in_progress':
      case 'inprogress':
      case 'investigating':
        return StatusBadge(label: _labelize(s), tone: StatusTone.info);
      // Orange — warned / refunded
      case 'warned':
      case 'refunded':
        return StatusBadge(label: _labelize(s), tone: StatusTone.orange);
      // Red — failure / blocked / flagged / disputed
      case 'suspended':
      case 'rejected':
      case 'cancelled':
      case 'disputed':
      case 'flagged':
      case 'open':
      case 'failed':
        return StatusBadge(label: _labelize(s), tone: StatusTone.error);
      // Neutral — hidden / closed / archived
      case 'hidden':
      case 'closed':
      case 'archived':
        return StatusBadge(label: _labelize(s), tone: StatusTone.neutral);
      default:
        return StatusBadge(label: _labelize(s), tone: StatusTone.neutral);
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
      case StatusTone.orange:
        return (AppColors.warningBg, AppColors.warning);
      case StatusTone.neutral:
        return (AppColors.neutral50, AppColors.neutral400);
    }
  }
}

enum StatusTone { success, warning, error, info, orange, neutral }
