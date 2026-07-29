import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const NavItem({required this.icon, required this.activeIcon, required this.label});
}

/// Shared bottom navigation bar shell for Client and Provider tab shells.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<NavItem> items;
  final void Function(int) onTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          items: [
            for (final item in items)
              BottomNavigationBarItem(
                icon: Icon(item.icon),
                activeIcon: Icon(item.activeIcon),
                label: item.label,
              ),
          ],
        ),
      ),
    );
  }
}
