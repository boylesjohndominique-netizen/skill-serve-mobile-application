import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../../models/provider_model.dart';
import '../misc/rating_widget.dart';
import '../feedback/shimmer_placeholder.dart';

/// Provider summary card — used in Browse Services, Search results, and
/// Favorites. Shows the platform's verification seal when applicable.
class ProviderCard extends StatelessWidget {
  final ProviderModel provider;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const ProviderCard({
    super.key,
    required this.provider,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.all(Radius.circular(AppSizes.radiusLg)),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: CachedNetworkImage(
                    imageUrl: provider.portfolioImages.isNotEmpty
                        ? provider.portfolioImages.first
                        : 'https://picsum.photos/seed/${provider.id}/200/200',
                    width: 68,
                    height: 68,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const ShimmerPlaceholder(width: 68, height: 68),
                  ),
                ),
                if (provider.isVerified)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.verified_rounded, size: 16, color: AppColors.secondary),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(provider.user.fullName, style: AppTextStyles.titleMedium, overflow: TextOverflow.ellipsis),
                      ),
                      InkWell(
                        onTap: onFavoriteToggle,
                        child: Icon(
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 19,
                          color: isFavorite ? AppColors.error : AppColors.neutral300,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(provider.categoryName, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      RatingWidget(rating: provider.averageRating, reviewCount: provider.reviewCount),
                      const SizedBox(width: 10),
                      const Icon(Icons.work_outline_rounded, size: 13, color: AppColors.neutral300),
                      const SizedBox(width: 3),
                      Text('${provider.completedJobs} jobs', style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (provider.startingPrice != null)
                    Text(
                      'From ${Formatters.peso(provider.startingPrice!)}',
                      style: AppTextStyles.label.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
