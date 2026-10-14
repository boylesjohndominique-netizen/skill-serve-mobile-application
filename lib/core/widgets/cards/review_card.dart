import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../../features/reviews/models/review_model.dart';
import '../misc/rating_widget.dart';
import '../misc/app_avatar.dart';
import '../misc/app_icon.dart';
import '../../constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// Single review entry used on Provider Profile and the provider's own
/// Reviews screen. Features soft shadow and dark-mode-aware colors.
class ReviewCard extends StatelessWidget {
  final ReviewModel review;

  /// Shows a "Report" action (and reports on long-press) when set. Leave
  /// null for a guest, or for the signed-in user's own review — the API
  /// refuses both.
  final VoidCallback? onReport;

  const ReviewCard({super.key, required this.review, this.onReport});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    final card = Container(
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
              AppAvatar(
                initials: review.clientName.isNotEmpty ? review.clientName[0].toUpperCase() : '?',
                radius: 16,
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
          // A labelled action, not a bare icon, so it is found.
          if (onReport != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReport,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                  minimumSize: const Size(48, 36),
                ),
                icon: AppIcon(AppIcons.flag_outlined, size: 14, color: context.textMutedColor),
                label: Text('Report', style: AppTextStyles.label.copyWith(color: context.textMutedColor)),
              ),
            ),
        ],
      ),
    );

    // Long-pressing the review offers the same report.
    return onReport == null
        ? card
        : Semantics(
            onLongPressHint: 'Report this review',
            child: GestureDetector(onLongPress: onReport, child: card),
          );
  }
}
