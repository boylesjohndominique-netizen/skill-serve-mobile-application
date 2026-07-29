import 'package:flutter/material.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../models/category_model.dart';

const Map<String, IconData> _categoryIcons = {
  'plumbing': Icons.plumbing_rounded,
  'bolt': Icons.bolt_rounded,
  'school': Icons.school_rounded,
  'brush': Icons.brush_rounded,
  'photo_camera': Icons.photo_camera_rounded,
  'carpenter': Icons.carpenter_rounded,
};

/// Compact category tile used in horizontal scrollers and category grids.
/// Features smooth selection animation with scale bounce and shadow.
class CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryCard({super.key, required this.category, this.selected = false, this.onTap});

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final icon = _categoryIcons[widget.category.icon] ?? Icons.work_outline_rounded;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : (widget.selected ? 1.04 : 1.0),
        duration: AppAnimations.fast,
        curve: AppAnimations.springCurve,
        child: AnimatedContainer(
          duration: AppAnimations.md,
          curve: AppAnimations.defaultCurve,
          width: 84,
          padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
          decoration: BoxDecoration(
            color: widget.selected ? AppColors.secondary : surfaceColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(
              color: widget.selected ? AppColors.secondary : lineColor,
              width: widget.selected ? 1.5 : 0.8,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : AppSizes.shadowFor(context, level: ShadowLevel.sm),
          ),
          child: Column(
            children: [
              AnimatedRotation(
                turns: widget.selected ? 0.02 : 0,
                duration: AppAnimations.md,
                child: Icon(icon, color: widget.selected ? Colors.white : AppColors.secondary, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                widget.category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: widget.selected ? Colors.white : (isDark ? AppColors.textMutedDark : AppColors.textSecondary),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
