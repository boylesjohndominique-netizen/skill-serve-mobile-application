import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../../features/marketplace/models/service_model.dart';
import '../misc/app_icon.dart';
import '../misc/rating_widget.dart';
import '../../../core/theme/app_palette.dart';

/// Service summary card — used by search results and any list of published
/// services. Mirrors [ProviderCard]'s visual language, with the price and
/// the owning provider in place of the provider's job stats.
class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;

  /// Opens the provider's profile from their name; the name is plain text
  /// when null.
  final VoidCallback? onProviderTap;

  const ServiceCard({super.key, required this.service, this.onTap, this.onProviderTap});

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
                    color: context.accentSoftColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: AppIcon(AppIcons.design_services_rounded, size: 20, color: context.onAccentSoftColor),
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
                      if (onProviderTap != null && service.providerName.isNotEmpty)
                        Row(
                          children: [
                            Flexible(
                              child: Semantics(
                                button: true,
                                label: 'View ${service.providerName}\'s profile',
                                excludeSemantics: true,
                                child: InkWell(
                                  onTap: onProviderTap,
                                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      service.providerName,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: context.accentInk,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.underline,
                                        decorationColor: context.accentInk,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (service.categoryName.isNotEmpty)
                              Flexible(
                                child: Text(
                                  ' • ${service.categoryName}',
                                  style: AppTextStyles.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        )
                      else
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
                                AppIcon(AppIcons.schedule_rounded, size: 13, color: context.textMutedColor),
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
                    color: context.accentInk,
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
