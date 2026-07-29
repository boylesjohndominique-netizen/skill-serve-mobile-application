import 'package:flutter/material.dart';
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

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Text('Profile', style: AppTextStyles.displayMedium),
            const SizedBox(height: AppSizes.lg),
            if (user != null)
              ProfileCard(
                user: user,
                onEdit: () => context.push('/edit-profile'),
                trailingBadge: StatusBadge.fromStatus(provider.verificationStatus),
              ),

            const SizedBox(height: AppSizes.xl),
            const _SectionLabel('Business'),
            _Tile(icon: Icons.design_services_outlined, label: 'My Services', onTap: () => context.push('/my-services')),
            _Tile(icon: Icons.bar_chart_rounded, label: 'Statistics', onTap: () => context.push('/statistics')),
            _Tile(icon: Icons.calendar_month_outlined, label: 'Calendar', onTap: () => context.push('/calendar')),
            _Tile(icon: Icons.reviews_outlined, label: 'Reviews', onTap: () => context.push('/reviews/${provider.id}')),
            _Tile(icon: Icons.payments_outlined, label: 'Earnings', onTap: () => context.push('/earnings')),
            _Tile(icon: Icons.verified_user_outlined, label: 'Verification Status', onTap: () => context.push('/verification-status')),

            const SizedBox(height: AppSizes.lg),
            const _SectionLabel('Account'),
            _Tile(icon: Icons.person_outline_rounded, label: 'Edit profile', onTap: () => context.push('/edit-profile')),
            _Tile(icon: Icons.lock_outline_rounded, label: 'Change password', onTap: () => context.push('/change-password')),
            _Tile(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () => context.push('/notifications')),

            const SizedBox(height: AppSizes.lg),
            const _SectionLabel('Preferences'),
            _SwitchTile(icon: Icons.dark_mode_outlined, label: 'Dark mode', value: theme.mode == ThemeMode.dark, onChanged: (_) => theme.toggle()),

            const SizedBox(height: AppSizes.lg),
            const _SectionLabel('Support'),
            _Tile(icon: Icons.help_outline_rounded, label: 'Help Center', onTap: () => context.push('/help-center')),
            _Tile(icon: Icons.description_outlined, label: 'Terms & Conditions', onTap: () => context.push('/terms')),
            _Tile(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () => context.push('/privacy')),

            const SizedBox(height: AppSizes.xl),
            _Tile(
              icon: Icons.logout_rounded,
              label: 'Log out',
              danger: true,
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
            ),
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
  const _Tile({required this.icon, required this.label, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: danger ? AppColors.error : AppColors.textSecondary, size: 21),
      title: Text(label, style: AppTextStyles.bodyLarge.copyWith(color: color)),
      trailing: danger ? null : const Icon(Icons.chevron_right_rounded, color: AppColors.neutral300),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final void Function(bool) onChanged;
  const _SwitchTile({required this.icon, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary, size: 21),
      title: Text(label, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary)),
      trailing: Switch(value: value, onChanged: onChanged, activeTrackColor: AppColors.secondary),
    );
  }
}
