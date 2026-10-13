import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../theme/app_palette.dart';

/// A titled card for one section of a detail screen (Statistics, a
/// service's reviews, a portfolio item) — the same surface, border and
/// spacing as the Profile menu's groups, so the screens read as one design.
class SectionCard extends StatelessWidget {
  final String title;

  /// A short line under the title, e.g. the period a chart covers.
  final String? subtitle;

  /// Shown at the right of the title, e.g. "See all" or a filter.
  final Widget? action;
  final Widget child;

  const SectionCard({super.key, required this.title, this.subtitle, this.action, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.titleMedium),
                    if (subtitle != null) Text(subtitle!, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: AppSizes.md),
          child,
        ],
      ),
    );
  }
}
