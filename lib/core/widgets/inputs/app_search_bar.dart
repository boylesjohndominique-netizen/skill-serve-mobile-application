import 'package:flutter/material.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// Search field with an optional trailing filter button — used on Browse,
/// Search, and Home screens.
/// Features animated shadow elevation on focus.
class AppSearchBar extends StatefulWidget {
  final String hint;
  final void Function(String)? onChanged;
  final VoidCallback? onFilterTap;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppSearchBar({
    super.key,
    this.hint = 'Search services or providers…',
    this.onChanged,
    this.onFilterTap,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;

    return Row(
      children: [
        Expanded(
          child: Focus(
            onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
            child: AnimatedContainer(
              duration: AppAnimations.md,
              curve: AppAnimations.defaultCurve,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: _focused ? AppColors.secondary.withValues(alpha: 0.4) : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: TextField(
                readOnly: widget.readOnly,
                onTap: widget.onTap,
                onChanged: widget.onChanged,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: AnimatedRotation(
                      turns: _focused ? 0.05 : 0,
                      duration: AppAnimations.md,
                      child: AppIcon(
                        AppIcons.search_rounded,
                        size: 17,
                        strokeWidth: 1.5,
                        color: _focused ? AppColors.secondary : AppColors.neutral300,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.onFilterTap != null) ...[
          const SizedBox(width: AppSizes.sm),
          InkWell(
            onTap: widget.onFilterTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const AppIcon(AppIcons.tune_rounded, color: Colors.white, size: 16, strokeWidth: 1.5),
            ),
          ),
        ],
      ],
    );
  }
}
