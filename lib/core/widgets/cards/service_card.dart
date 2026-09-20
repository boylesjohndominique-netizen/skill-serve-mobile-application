import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../../features/marketplace/models/service_model.dart';
import '../misc/app_icon.dart';
import '../misc/rating_widget.dart';

/// Service summary card — used by search results and any list of published
/// services. Mirrors [ProviderCard]'s visual language, with the price and
/// the owning provider in place of the provider's job stats.
class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return Semantics(
      button: onTap != null,
      label: 'Service ${service.title}',
      child: Material(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
              boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const AppIcon(AppIcons.design_services_rounded, size: 20, color: AppColors.secondaryDeep),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (service.providerName.isNotEmpty) service.providerName,
                          if (service.categoryName.isNotEmpty) service.categoryName,
                        ].join(' • '),
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          RatingWidget(rating: service.averageRating, reviewCount: service.reviewCount),
                          if (service.duration.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const AppIcon(AppIcons.schedule_rounded, size: 13, color: AppColors.neutral300),
                                const SizedBox(width: 3),
                                Text(service.duration, style: AppTextStyles.bodySmall),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  service.isQuoteOnly ? 'On quote' : Formatters.peso(service.price),
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
