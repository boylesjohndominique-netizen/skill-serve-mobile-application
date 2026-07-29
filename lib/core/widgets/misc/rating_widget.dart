import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

/// Compact star rating display used across provider cards, reviews, and
/// booking summaries. Read-only — no interactive rating input needed here.
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
        Icon(Icons.star_rounded, size: size, color: AppColors.star),
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
