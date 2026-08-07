import 'package:flutter/material.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// KPI stat tile — used on the provider dashboard and statistics screens.
/// Ink card with a brass icon, mono value, and label. Includes the standard
/// press-scale micro-animation when [onTap] is provided.
class StatCard extends StatefulWidget {
  final String label;
  final String value;
  final AppIconData icon;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    final card = AnimatedContainer(
      duration: AppAnimations.fast,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: AppColors.surfaceGradient,
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
        boxShadow: _pressed
            ? AppSizes.shadowFor(context, level: ShadowLevel.sm)
            : AppSizes.shadowFor(context, level: ShadowLevel.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(widget.icon, color: AppColors.secondary, size: 20),
          const SizedBox(height: 8),
          Text(
            widget.value,
            style: AppTextStyles.monoMd.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(widget.label, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );

    if (widget.onTap == null) return card;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? AppAnimations.cardPressScale : 1.0,
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        child: card,
      ),
    );
  }
}
