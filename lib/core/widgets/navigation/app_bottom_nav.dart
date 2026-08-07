import 'package:flutter/material.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

class NavItem {
  final AppIconData icon;
  final AppIconData activeIcon;
  final String label;
  const NavItem({required this.icon, required this.activeIcon, required this.label});
}

/// Premium bottom navigation bar with animated sliding pill indicator,
/// icon scale animation on selection, and refined shadow.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<NavItem> items;
  final void Function(int) onTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              final item = items[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: _NavItemWidget(
                    item: item,
                    selected: selected,
                    isDark: isDark,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final bool isDark;

  const _NavItemWidget({
    required this.item,
    required this.selected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.md,
      curve: AppAnimations.defaultCurve,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated icon with scale
          AnimatedScale(
            scale: selected ? 1.15 : 1.0,
            duration: AppAnimations.md,
            curve: AppAnimations.springCurve,
            child: AnimatedSwitcher(
              duration: AppAnimations.fast,
              child: AppIcon(
                selected ? item.activeIcon : item.icon,
                key: ValueKey('${item.label}_$selected'),
                size: 24,
                color: selected ? AppColors.secondary : AppColors.neutral300,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Animated label
          AnimatedDefaultTextStyle(
            duration: AppAnimations.fast,
            style: AppTextStyles.caption.copyWith(
              color: selected ? AppColors.secondary : AppColors.neutral300,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: selected ? 11.5 : 10.5,
            ),
            child: Text(item.label),
          ),
          const SizedBox(height: 4),
          // Pill indicator
          AnimatedContainer(
            duration: AppAnimations.md,
            curve: AppAnimations.defaultCurve,
            width: selected ? 20 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: selected ? AppColors.secondary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
          ),
        ],
      ),
    );
  }
}
