import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../theme/app_palette.dart';
import 'app_icon.dart';

/// A rating at a glance — the average, its stars, how many reviews, and a
/// bar per star — used wherever a rating is summarised (service details, a
/// service's reviews, the provider's statistics) so they all read the same.
///
/// [breakdown] maps stars (5…1) to how many reviews gave them; [selected]
/// highlights one row, and [onSelect] makes the rows filters.
class RatingSummary extends StatelessWidget {
  final double average;
  final int total;
  final Map<int, int> breakdown;
  final int? selected;
  final ValueChanged<int?>? onSelect;

  const RatingSummary({
    super.key,
    required this.average,
    required this.total,
    required this.breakdown,
    this.selected,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 92,
          child: Column(
            children: [
              Text(total == 0 ? '–' : average.toStringAsFixed(1), style: AppTextStyles.displayMedium),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var star = 1; star <= 5; star++)
                    AppIcon(
                      AppIcons.star_rounded,
                      size: 13,
                      // Filled and empty stars share a glyph; colour tells them apart.
                      color: star <= average.round() && total > 0
                          ? context.starColor
                          : context.textMutedColor.withValues(alpha: 0.4),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                total == 1 ? '1 review' : '$total reviews',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            children: [
              for (final star in const [5, 4, 3, 2, 1]) _row(context, star),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, int star) {
    final count = breakdown[star] ?? 0;
    final share = total == 0 ? 0.0 : count / total;
    final isSelected = selected == star;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 12,
            child: Text('$star', style: AppTextStyles.label.copyWith(fontWeight: isSelected ? FontWeight.w800 : null)),
          ),
          AppIcon(AppIcons.star_rounded, size: 11, color: context.starColor),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: share),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: context.surfaceAltColor,
                  valueColor: AlwaysStoppedAnimation(isSelected || selected == null ? context.starColor : context.textMutedColor),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 26,
            child: Text('$count', style: AppTextStyles.bodySmall, textAlign: TextAlign.right),
          ),
        ],
      ),
    );

    if (onSelect == null) return row;
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$star stars, $count reviews',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        // Tapping the selected row again clears the filter.
        onTap: () => onSelect!(isSelected ? null : star),
        child: row,
      ),
    );
  }
}
