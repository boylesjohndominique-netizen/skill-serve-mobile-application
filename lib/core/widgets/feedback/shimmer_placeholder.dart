import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

/// Generic shimmering block — drop into any layout while content loads.
/// Dark-mode-aware shimmer colors.
class ShimmerPlaceholder extends StatelessWidget {
  final double? height;
  final double? width;
  final double borderRadius;

  const ShimmerPlaceholder({super.key, this.height, this.width, this.borderRadius = AppSizes.radiusMd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.surfaceAltDark : AppColors.neutral100,
      highlightColor: isDark ? AppColors.surfaceDark : AppColors.neutral50,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceAltDark : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Preset shimmer skeleton mimicking a provider/category card list —
/// used while [MarketplaceController] loads.
class ShimmerCardList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const ShimmerCardList({super.key, this.count = 4, this.itemHeight = 96});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.md),
          child: ShimmerPlaceholder(height: itemHeight, borderRadius: AppSizes.radiusLg),
        ),
      ),
    );
  }
}
