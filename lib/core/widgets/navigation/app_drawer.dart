import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../models/user_model.dart';

class DrawerAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const DrawerAction({required this.icon, required this.label, required this.onTap});
}

/// Slide-out drawer offering secondary navigation (Help, Terms, Logout…)
/// so the bottom nav can stay limited to five primary destinations.
class AppDrawer extends StatelessWidget {
  final UserModel? user;
  final List<DrawerAction> actions;
  final VoidCallback onLogout;

  const AppDrawer({super.key, required this.user, required this.actions, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user?.initials ?? 'G',
                      style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
                    ),
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
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                children: [
                  for (final action in actions)
                    ListTile(
                      leading: Icon(action.icon, color: AppColors.textSecondary, size: 22),
                      title: Text(action.label, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary)),
                      onTap: action.onTap,
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
              title: Text('Log out', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error)),
              onTap: onLogout,
            ),
            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }
}
