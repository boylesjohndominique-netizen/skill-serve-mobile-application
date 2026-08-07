import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// Compact star rating display used across provider cards, reviews, and
/// booking summaries. Read-only — no interactive rating input needed here.
/// Stars shimmer briefly on first render for visual polish.
class RatingWidget extends StatelessWidget {
  final double rating;
  final int? reviewCount;
  final double size;

  const RatingWidget({super.key, required this.rating, this.reviewCount, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(AppIcons.star_rounded, size: size, color: AppColors.star)
            .animate()
            .shimmer(duration: 800.ms, delay: 200.ms, color: AppColors.secondaryLight.withValues(alpha: 0.5)),
        const SizedBox(width: 3),
        Text(rating.toStringAsFixed(1), style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
        if (reviewCount != null) ...[
          const SizedBox(width: 3),
          Text('($reviewCount)', style: AppTextStyles.bodySmall),
        ],
      ],
    );
  }
}
