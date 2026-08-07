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
    // ListView (shrink-wrapped, non-scrollable) so the skeleton never
    // overflows whatever bounded height it is dropped into.
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
      itemBuilder: (_, i) => ShimmerPlaceholder(height: itemHeight, borderRadius: AppSizes.radiusLg),
    );
  }
}
