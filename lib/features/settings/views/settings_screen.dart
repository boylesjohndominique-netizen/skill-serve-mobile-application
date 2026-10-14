import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../profile/views/account_status_card.dart';

import '../controllers/preferences_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cards/profile_card.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/misc/app_avatar.dart';
import 'settings_menu.dart';
import '../../../core/constants/app_icons.dart';

/// Client's Profile / Settings tab. Reused as a template pattern for the
/// Provider settings screen (see provider/settings_screen.dart).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final preferences = context.watch<PreferencesController>();
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Text('Profile', style: AppTextStyles.displayMedium)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: AppSizes.lg),
            if (user != null)
              // No edit button here: Edit profile is in the Account group.
              ProfileCard(user: user)
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 350.ms)
                  .slideY(begin: 0.06, end: 0)
            else
              const _GuestCard(),
            if (user != null) ...[
              const SizedBox(height: AppSizes.md),
              AccountStatusCard(user: user),
            ],
            const SizedBox(height: AppSizes.xl),
            // Each category opens to show its items, so the tab stays short.
            // A guest has no account, activity or data to manage yet.
            if (user != null) ...[
              SettingsGroup(
                icon: AppIcons.person_outline_rounded,
                title: 'Account',
                summary: 'Profile, ID verification, password',
                children: [
                  SettingsTile(icon: AppIcons.person_outline_rounded, label: 'Edit profile', onTap: () => context.push('/edit-profile')),
                  SettingsTile(icon: AppIcons.badge_outlined, label: 'Identity verification', onTap: () => context.push('/identity-verification')),
                  SettingsTile(icon: AppIcons.lock_outline_rounded, label: 'Change password', onTap: () => context.push('/change-password')),
                ],
              ),
              SettingsGroup(
                icon: AppIcons.history_rounded,
                title: 'Activity',
                summary: 'Favorites, payments, reviews',
                children: [
                  // Notifications open from the bell on Home.
                  SettingsTile(icon: AppIcons.favorite_border_rounded, label: 'Favorite providers', onTap: () => context.push('/favorites')),
                  SettingsTile(icon: AppIcons.receipt_long_outlined, label: 'Payments & receipts', onTap: () => context.push('/payments')),
                  SettingsTile(icon: AppIcons.star_outline_rounded, label: 'My reviews', onTap: () => context.push('/my-reviews')),
                  SettingsTile(icon: AppIcons.history_rounded, label: 'Activity history', onTap: () => context.push('/activity-history')),
                ],
              ),
              // Two kinds of case, each on its own screen: complaints about
              // people, and disputes about a booking.
              SettingsGroup(
                icon: AppIcons.flag_outlined,
                title: 'Reports & disputes',
                summary: 'Reports you filed, booking disputes',
                children: [
                  SettingsTile(icon: AppIcons.flag_outlined, label: 'My reports', onTap: () => context.push('/my-reports')),
                  SettingsTile(icon: AppIcons.gavel_rounded, label: 'My disputes', onTap: () => context.push('/my-disputes')),
                ],
              ),
            ],
            SettingsGroup(
              icon: AppIcons.tune_rounded,
              title: 'Preferences',
              summary: 'Dark mode, notifications, privacy',
              children: [
                SettingsSwitchTile(
                  icon: AppIcons.dark_mode_outlined,
                  label: 'Dark mode',
                  value: isDark,
                  onChanged: (dark) => preferences.setDarkMode(dark,
                      phoneIsDark: MediaQuery.platformBrightnessOf(context) == Brightness.dark),
                ),
                SettingsTile(icon: AppIcons.notifications_none_rounded, label: 'Notification preferences', onTap: () => context.push('/notification-preferences')),
                SettingsTile(icon: AppIcons.privacy_tip_outlined, label: 'Privacy settings', onTap: () => context.push('/privacy-settings')),
                SettingsTile(icon: AppIcons.apps_rounded, label: 'Application preferences', onTap: () => context.push('/application-preferences')),
                SettingsTile(icon: AppIcons.verified_user_outlined, label: 'Security activity', onTap: () => context.push('/security-activity')),
              ],
            ),
            SettingsGroup(
              icon: AppIcons.help_outline_rounded,
              title: 'Help & support',
              summary: 'Customer Support, help center, policies',
              children: [
                if (user != null)
                  SettingsTile(icon: AppIcons.support_agent_rounded, label: 'Customer Support', onTap: () => context.push('/support/tickets')),
                SettingsTile(icon: AppIcons.help_outline_rounded, label: 'Help Center', onTap: () => context.push('/help-center')),
                SettingsTile(icon: AppIcons.info_outline_rounded, label: 'About SkillServe', onTap: () => context.push('/about')),
                SettingsTile(icon: AppIcons.description_outlined, label: 'Terms & Conditions', onTap: () => context.push('/terms')),
                SettingsTile(icon: AppIcons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () => context.push('/privacy')),
                SettingsTile(icon: AppIcons.groups_outlined, label: 'Community Guidelines', onTap: () => context.push('/community-guidelines')),
              ],
            ),
            if (user != null)
              SettingsGroup(
                icon: AppIcons.description_outlined,
                title: 'Your data',
                summary: 'View your account data',
                children: [
                  SettingsTile(icon: AppIcons.description_outlined, label: 'View account data', onTap: () => context.push('/account-data')),
                ],
              ),
            const SizedBox(height: AppSizes.md),
            SettingsSessionButton(
              signedIn: user != null,
              onPressed: () async {
                if (user == null) {
                  context.go('/login');
                  return;
                }
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
            ),
            const SizedBox(height: AppSizes.lg),
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
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          const AppAvatar(
            fallbackIcon: AppIcons.person,
            radius: 26,
            backgroundColor: AppColors.secondary,
            foregroundColor: AppColors.primary,
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You\'re browsing as a guest',
                    style: AppTextStyles.onDark(AppTextStyles.titleMedium)),
                Text('Log in to book and message providers',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textMutedDark)),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 80.ms, duration: 350.ms)
        .slideY(begin: 0.06, end: 0);
  }
}
