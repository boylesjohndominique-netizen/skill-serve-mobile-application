import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../../models/review_model.dart';
import '../misc/rating_widget.dart';

/// Single review entry used on Provider Profile and the provider's own
/// Reviews screen. Features soft shadow and dark-mode-aware colors.
class ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
        boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Text(
                  review.clientName.isNotEmpty ? review.clientName[0] : '?',
                  style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.clientName, style: AppTextStyles.titleMedium),
                    Text(Formatters.relative(review.createdAt), style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              RatingWidget(rating: review.rating),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text(review.comment, style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.textMutedDark : AppColors.textSecondary,
          )),
        ],
      ),
    );
  }
}
