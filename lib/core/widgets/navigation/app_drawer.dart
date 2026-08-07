import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../models/user_model.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/app_avatar.dart';
import '../../../core/constants/app_icons.dart';

class DrawerAction {
  final AppIconData icon;
  final String label;
  final VoidCallback onTap;
  const DrawerAction({required this.icon, required this.label, required this.onTap});
}

/// Slide-out drawer offering secondary navigation (Help, Terms, Logout…)
/// so the bottom nav can stay limited to five primary destinations.
/// Features staggered entrance animation for drawer items.
class AppDrawer extends StatelessWidget {
  final UserModel? user;
  final List<DrawerAction> actions;
  final VoidCallback onLogout;

  const AppDrawer({super.key, required this.user, required this.actions, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;

    return Drawer(
      backgroundColor: surfaceColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                children: [
                  AppAvatar(
                    initials: user?.initials ?? 'G',
                    radius: 26,
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1.0, 1.0),
                        duration: AppAnimations.md,
                        curve: AppAnimations.springCurve,
                      ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.fullName ?? 'Guest', style: AppTextStyles.titleLarge),
                        Text(user?.email ?? 'Browsing as guest', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: AppAnimations.md, delay: 100.ms)
                      .slideX(begin: 0.1, end: 0),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                children: [
                  for (var i = 0; i < actions.length; i++)
                    ListTile(
                      leading: AppIcon(actions[i].icon, color: isDark ? AppColors.textMutedDark : AppColors.textSecondary, size: 22),
                      title: Text(actions[i].label, style: AppTextStyles.bodyLarge),
                      onTap: actions[i].onTap,
                    )
                        .animate()
                        .fadeIn(
                          duration: AppAnimations.md,
                          delay: AppAnimations.staggerDelay(i, base: 50.ms),
                        )
                        .slideX(begin: 0.08, end: 0),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const AppIcon(AppIcons.logout_rounded, color: AppColors.error, size: 22),
              title: Text('Log out', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error)),
              onTap: onLogout,
            )
                .animate()
                .fadeIn(duration: AppAnimations.md, delay: 300.ms),
            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }
}
