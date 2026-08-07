import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// The signature VERIFICATION SEAL — a dashed circular "stamp" used
/// everywhere trust is shown (verified provider, approved document,
/// account status). Mirrors the admin console's badge motif.
///
/// States:
///  - verified                 → emerald stamp, shield-check icon
///  - pending                  → brass stamp, clock icon (pulses)
///  - resubmission_requested   → brass stamp, rotate icon
///  - rejected / suspended     → red stamp, close icon
///
/// Sizes follow the design spec: 26 / 34 / 44 / 60.
class VerificationSeal extends StatelessWidget {
  final String status;
  final double size;
  final bool showLabel;

  const VerificationSeal({
    super.key,
    required this.status,
    this.size = 44,
    this.showLabel = false,
  });

  ({Color color, Color soft, AppIconData icon, String label}) get _state {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'approved':
        return (
          color: AppColors.success,
          soft: AppColors.successBg,
          icon: AppIcons.verified_rounded,
          label: 'Verified',
        );
      case 'rejected':
      case 'suspended':
        return (
          color: AppColors.error,
          soft: AppColors.errorBg,
          icon: AppIcons.close_rounded,
          label: 'Rejected',
        );
      case 'resubmission_requested':
        return (
          color: AppColors.warning,
          soft: AppColors.warningBg,
          icon: AppIcons.rotate_left_rounded,
          label: 'Resubmit',
        );
      case 'pending':
      default:
        return (
          color: AppColors.warning,
          soft: AppColors.warningBg,
          icon: AppIcons.hourglass_top_rounded,
          label: 'Under review',
        );
    }
  }

  bool get _pulses => status.toLowerCase() == 'pending';

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final stroke = size >= 44 ? 2.2 : (size >= 34 ? 1.8 : 1.5);

    Widget seal = SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dashed stamp ring
          CustomPaint(
            size: Size.square(size),
            painter: _DashedCirclePainter(color: state.color, strokeWidth: stroke),
          ),
          // Soft inner disc
          Container(
            width: size * 0.72,
            height: size * 0.72,
            decoration: BoxDecoration(
              color: state.soft,
              shape: BoxShape.circle,
            ),
          ),
          AppIcon(state.icon, color: state.color, size: size * 0.42),
        ],
      ),
    );

    if (_pulses) {
      seal = seal
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.05, duration: 1400.ms, curve: Curves.easeInOut);
    }

    if (!showLabel) return seal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        seal,
        const SizedBox(height: AppSizes.sm),
        Text(
          state.label.toUpperCase(),
          style: AppTextStyles.eyebrow.copyWith(color: state.color),
        ),
      ],
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DashedCirclePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    const dashCount = 26.0;
    const sweep = 2 * math.pi / dashCount;
    const dashSweep = sweep / 2.4; // dash : gap ≈ 1 : 1.4
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < dashCount; i++) {
      final start = i * sweep + 0.01;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        dashSweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
