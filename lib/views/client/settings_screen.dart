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

/// Client's Profile / Settings tab. Reused as a template pattern for the
/// Provider settings screen (see provider/settings_screen.dart).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = context.watch<ThemeController>();
    final user = auth.currentUser;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Text('Profile', style: AppTextStyles.displayMedium),
            const SizedBox(height: AppSizes.lg),
            if (user != null)
              ProfileCard(user: user, onEdit: () => context.push('/edit-profile'))
            else
              const _GuestCard(),
            const SizedBox(height: AppSizes.xl),

            const _SectionLabel('Account'),
            _Tile(icon: Icons.person_outline_rounded, label: 'Edit profile', onTap: () => context.push('/edit-profile')),
            _Tile(icon: Icons.lock_outline_rounded, label: 'Change password', onTap: () => context.push('/change-password')),
            _Tile(icon: Icons.favorite_border_rounded, label: 'Favorite providers', onTap: () => context.push('/favorites')),
            _Tile(icon: Icons.notifications_none_rounded, label: 'Notifications', onTap: () => context.push('/notifications')),

            const SizedBox(height: AppSizes.lg),
            const _SectionLabel('Preferences'),
            _SwitchTile(
              icon: Icons.dark_mode_outlined,
              label: 'Dark mode',
              value: theme.mode == ThemeMode.dark,
              onChanged: (_) => theme.toggle(),
            ),

            const SizedBox(height: AppSizes.lg),
            const _SectionLabel('Support'),
            _Tile(icon: Icons.help_outline_rounded, label: 'Help Center', onTap: () => context.push('/help-center')),
            _Tile(icon: Icons.info_outline_rounded, label: 'About SkillLink', onTap: () => context.push('/about')),
            _Tile(icon: Icons.description_outlined, label: 'Terms & Conditions', onTap: () => context.push('/terms')),
            _Tile(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () => context.push('/privacy')),

            const SizedBox(height: AppSizes.xl),
            if (user != null)
              _Tile(
                icon: Icons.logout_rounded,
                label: 'Log out',
                danger: true,
                onTap: () async {
                  final confirmed = await AppDialog.confirm(
                    context,
                    title: 'Log out?',
                    message: 'You\'ll need to log in again to book services or view your history.',
                    confirmLabel: 'Log out',
                    danger: true,
                  );
                  if (confirmed) {
                    await auth.logout();
                    if (context.mounted) context.go('/welcome');
                  }
                },
              )
            else
              _Tile(icon: Icons.login_rounded, label: 'Log in', onTap: () => context.go('/login')),
          ],
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
      child: Row(
        children: [
          const CircleAvatar(radius: 26, backgroundColor: AppColors.secondary, child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You\'re browsing as a guest', style: AppTextStyles.onDark(AppTextStyles.titleMedium)),
                Text('Log in to book and message providers', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark)),
              ],
            ),
          ),
        ],
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
