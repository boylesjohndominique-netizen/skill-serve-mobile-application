import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../theme/app_palette.dart';
import '../../utils/formatters.dart';
import '../../../features/provider/models/portfolio_model.dart';
import '../feedback/shimmer_placeholder.dart';
import '../misc/app_icon.dart';

/// A piece of work as a card — cover photo with a photo count, title and
/// date — used by the provider's Portfolio, the customer's gallery and the
/// profile, so a portfolio looks the same wherever it appears.
class PortfolioCard extends StatelessWidget {
  final PortfolioModel item;
  final VoidCallback onTap;

  const PortfolioCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final cover = item.photoUrls.isEmpty ? null : item.photoUrls.first;

    return Semantics(
      button: true,
      label: '${item.title}, ${item.photoCount} ${item.photoCount == 1 ? 'photo' : 'photos'}',
      excludeSemantics: true,
      child: Material(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (cover == null)
                        Container(
                          color: context.accentSoftColor,
                          child: AppIcon(AppIcons.photo_library_outlined, color: context.onAccentSoftColor),
                        )
                      else
                        CachedNetworkImage(
                          imageUrl: cover,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ShimmerPlaceholder(),
                          errorWidget: (_, __, ___) => Container(
                            color: context.accentSoftColor,
                            child: AppIcon(AppIcons.broken_image_outlined, color: context.onAccentSoftColor),
                          ),
                        ),
                      if (item.photoCount > 1)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const AppIcon(AppIcons.photo_library_outlined, size: 12, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  '${item.photoCount}',
                                  style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.sm, AppSizes.sm, AppSizes.sm, AppSizes.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: AppTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (item.createdAt != null)
                        Text(Formatters.dateShort(item.createdAt!), style: AppTextStyles.caption),
                    ],
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
