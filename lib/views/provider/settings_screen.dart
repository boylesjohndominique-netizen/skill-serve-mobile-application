import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/cards/profile_card.dart';
import '../../core/widgets/feedback/app_dialog.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../data/mock/mock_data.dart';

/// Provider's Profile tab — account, business tools, and preferences.
class ProviderSettingsScreen extends StatelessWidget {
  const ProviderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = context.watch<ThemeController>();
    final user = auth.currentUser;
    final provider = MockData.providers.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int idx = 0;
    Widget stagger(Widget child) {
      final delay = Duration(milliseconds: 100 + (idx++) * 40);
      return child.animate().fadeIn(delay: delay, duration: 300.ms).slideX(begin: 0.04, end: 0);
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Text('Profile', style: AppTextStyles.displayMedium)
                .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
            const SizedBox(height: AppSizes.lg),
            if (user != null)
              ProfileCard(
                user: user,
                onEdit: () => context.push('/edit-profile'),
                trailingBadge: StatusBadge.fromStatus(provider.verificationStatus),
              ).animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),

            const SizedBox(height: AppSizes.xl),
            stagger(_SectionLabel('Business')),
            stagger(_Tile(icon: Icons.design_services_outlined, label: 'My Services', onTap: () => context.push('/my-services'), isDark: isDark)),
            stagger(_Tile(icon: Icons.bar_chart_rounded, label: 'Statistics', onTap: () => context.push('/statistics'), isDark: isDark)),
            stagger(_Tile(icon: Icons.calendar_month_outlined, label: 'Calendar', onTap: () => context.push('/calendar'), isDark: isDark)),
            stagger(_Tile(icon: Icons.reviews_outlined, label: 'Reviews', onTap: () => context.push('/reviews/${provider.id}'), isDark: isDark)),
            stagger(_Tile(icon: Icons.payments_outlined, label: 'Earnings', onTap: () => context.push('/earnings'), isDark: isDark)),
            stagger(_Tile(icon: Icons.verified_user_outlined, label: 'Verification Status', onTap: () => context.push('/verification-status'), isDark: isDark)),

            const SizedBox(height: AppSizes.lg),
            stagger(_SectionLabel('Account')),
            stagger(_Tile(icon: Icons.person_outline_rounded, label: 'Edit profile', onTap: () => context.push('/edit-profile'), isDark: isDark)),
            stagger(_Tile(icon: Icons.lock_outline_rounded, label: 'Change password', onTap: () => context.push('/change-password'), isDark: isDark)),
            stagger(_Tile(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () => context.push('/notifications'), isDark: isDark)),

            const SizedBox(height: AppSizes.lg),
            stagger(_SectionLabel('Preferences')),
            stagger(_SwitchTile(icon: Icons.dark_mode_outlined, label: 'Dark mode', value: theme.mode == ThemeMode.dark, onChanged: (_) => theme.toggle(), isDark: isDark)),

            const SizedBox(height: AppSizes.lg),
            stagger(_SectionLabel('Support')),
            stagger(_Tile(icon: Icons.help_outline_rounded, label: 'Help Center', onTap: () => context.push('/help-center'), isDark: isDark)),
            stagger(_Tile(icon: Icons.description_outlined, label: 'Terms & Conditions', onTap: () => context.push('/terms'), isDark: isDark)),
            stagger(_Tile(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () => context.push('/privacy'), isDark: isDark)),

            const SizedBox(height: AppSizes.xl),
            stagger(_Tile(
              icon: Icons.logout_rounded,
              label: 'Log out',
              danger: true,
              isDark: isDark,
              onTap: () async {
                final confirmed = await AppDialog.confirm(
                  context,
                  title: 'Log out?',
                  message: 'You\'ll need to log in again to manage bookings or your services.',
                  confirmLabel: 'Log out',
                  danger: true,
                );
                if (confirmed) {
                  await auth.logout();
                  if (context.mounted) context.go('/welcome');
                }
              },
            )),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm, top: AppSizes.sm),
      child: Text(label.toUpperCase(), style: AppTextStyles.overline),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final bool isDark;
  const _Tile({required this.icon, required this.label, required this.onTap, this.danger = false, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : (isDark ? AppColors.textOnDark : AppColors.textPrimary);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: danger ? AppColors.error : (isDark ? AppColors.textMutedDark : AppColors.textSecondary), size: 21),
      title: Text(label, style: AppTextStyles.bodyLarge.copyWith(color: color)),
      trailing: danger ? null : Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.neutral400 : AppColors.neutral300),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final void Function(bool) onChanged;
  final bool isDark;
  const _SwitchTile({required this.icon, required this.label, required this.value, required this.onChanged, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isDark ? AppColors.textMutedDark : AppColors.textSecondary, size: 21),
      title: Text(label, style: AppTextStyles.bodyLarge.copyWith(color: isDark ? AppColors.textOnDark : AppColors.textPrimary)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
