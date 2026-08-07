import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// Small pill badge for statuses (booking status, verification status, etc.)
/// Mirrors the color logic used on the Admin Web Application for consistency:
/// icon + label pill. Active/in-progress statuses get a subtle pulse animation.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusTone tone;
  final AppIconData? icon;

  const StatusBadge({super.key, required this.label, required this.tone, this.icon});

  /// Maps every status enum (Section 4) to the admin console's Badge colors
  /// (Section 10): emerald (success), brass (pending), blue (progress),
  /// orange (warning), red (failure/blocked), neutral (hidden/closed).
  factory StatusBadge.fromStatus(String status) {
    final s = status.toLowerCase().replaceAll(' ', '_');
    switch (s) {
      // Emerald — success / verified / paid / completed / sent
      case 'active':
        return const StatusBadge(label: 'Active', tone: StatusTone.success, icon: AppIcons.check_rounded);
      case 'verified':
      case 'approved':
        return const StatusBadge(label: 'Verified', tone: StatusTone.success, icon: AppIcons.verified_rounded);
      case 'completed':
        return const StatusBadge(label: 'Completed', tone: StatusTone.success, icon: AppIcons.task_alt_rounded);
      case 'visible':
        return const StatusBadge(label: 'Visible', tone: StatusTone.success, icon: AppIcons.visibility_outlined);
      case 'sent':
        return const StatusBadge(label: 'Sent', tone: StatusTone.success, icon: AppIcons.send_rounded);
      case 'paid':
        return const StatusBadge(label: 'Paid', tone: StatusTone.success, icon: AppIcons.check_circle_rounded);
      // Brass — pending / confirmed / resubmission
      case 'pending':
        return const StatusBadge(label: 'Pending', tone: StatusTone.warning, icon: AppIcons.hourglass_top_rounded);
      case 'confirmed':
        return const StatusBadge(label: 'Confirmed', tone: StatusTone.warning, icon: AppIcons.event_available_rounded);
      case 'resubmission_requested':
        return const StatusBadge(label: 'Resubmission Requested', tone: StatusTone.warning, icon: AppIcons.rotate_left_rounded);
      case 'resubmit':
        return const StatusBadge(label: 'Resubmit', tone: StatusTone.warning, icon: AppIcons.rotate_left_rounded);
      // Blue — in progress / investigating
      case 'in_progress':
      case 'inprogress':
        return const StatusBadge(label: 'In Progress', tone: StatusTone.info, icon: AppIcons.play_arrow_rounded);
      case 'investigating':
        return const StatusBadge(label: 'Investigating', tone: StatusTone.info, icon: AppIcons.search_rounded);
      // Orange — warned / refunded
      case 'warned':
        return const StatusBadge(label: 'Warned', tone: StatusTone.orange, icon: AppIcons.warning_amber_rounded);
      case 'refunded':
        return const StatusBadge(label: 'Refunded', tone: StatusTone.orange, icon: AppIcons.currency_exchange_rounded);
      // Red — failure / blocked / flagged / disputed
      case 'suspended':
        return const StatusBadge(label: 'Suspended', tone: StatusTone.error, icon: AppIcons.block_rounded);
      case 'rejected':
        return const StatusBadge(label: 'Rejected', tone: StatusTone.error, icon: AppIcons.close_rounded);
      case 'cancelled':
        return const StatusBadge(label: 'Cancelled', tone: StatusTone.error, icon: AppIcons.cancel_outlined);
      case 'disputed':
        return const StatusBadge(label: 'Disputed', tone: StatusTone.error, icon: AppIcons.gavel_rounded);
      case 'flagged':
        return const StatusBadge(label: 'Flagged', tone: StatusTone.error, icon: AppIcons.flag_rounded);
      case 'open':
        return const StatusBadge(label: 'Open', tone: StatusTone.error, icon: AppIcons.flag_outlined);
      case 'failed':
        return const StatusBadge(label: 'Failed', tone: StatusTone.error, icon: AppIcons.error_rounded);
      // Neutral — hidden / closed / archived
      case 'hidden':
        return const StatusBadge(label: 'Hidden', tone: StatusTone.neutral, icon: AppIcons.visibility_off_outlined);
      case 'closed':
        return const StatusBadge(label: 'Closed', tone: StatusTone.neutral, icon: AppIcons.close_rounded);
      case 'archived':
        return const StatusBadge(label: 'Archived', tone: StatusTone.neutral, icon: AppIcons.inbox_outlined);
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: colors.$2.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon(icon, size: 12, color: colors.$2),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: colors.$2, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );

    if (_shouldPulse) {
      badge = badge
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(
            begin: 1.0,
            end: 1.04,
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
        // Brass (not amber) — pending/confirmed/resubmission per the design spec.
        return (AppColors.secondarySoft, AppColors.secondaryDeep);
      case StatusTone.error:
        return (AppColors.errorBg, AppColors.error);
      case StatusTone.info:
        return (AppColors.infoBg, AppColors.info);
      case StatusTone.orange:
        return (AppColors.warningBg, AppColors.warning);
      case StatusTone.neutral:
        return (AppColors.neutral100, AppColors.neutral400);
    }
  }
}

enum StatusTone { success, warning, error, info, orange, neutral }
