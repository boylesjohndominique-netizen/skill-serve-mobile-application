import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../profile/views/account_status_card.dart';

import '../../settings/controllers/preferences_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cards/profile_card.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/misc/status_badge.dart';
import '../../../core/constants/app_icons.dart';
import '../../marketplace/models/provider_model.dart';
import '../services/provider_service_service.dart';
import '../../settings/views/settings_menu.dart';

/// Provider's Profile tab — business tools, earnings, account and
/// preferences, each a group that opens to show its items.
class ProviderSettingsScreen extends StatefulWidget {
  const ProviderSettingsScreen({super.key});

  @override
  State<ProviderSettingsScreen> createState() => _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState extends State<ProviderSettingsScreen> {
  ProviderModel? _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProvider());
  }

  Future<void> _loadProvider() async {
    if (context.read<AuthController>().currentUser == null) return;
    final ProviderModel provider;
    try {
      provider = await ProviderServiceService().getMyProfile();
    } catch (_) {
      return; // Keep the screen usable without profile details.
    }
    if (mounted) setState(() => _provider = provider);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final preferences = context.watch<PreferencesController>();
    final user = auth.currentUser;
    final provider = _provider;
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
              ProfileCard(
                user: user,
                onEdit: () => context.push('/edit-profile'),
                trailingBadge:
                    // The live account status, refreshed by verification
                    // notifications; the profile loaded on open is a fallback.
                    StatusBadge.fromStatus(user.providerVerificationStatus ??
                        provider?.verificationStatus ??
                        'pending'),
              )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 350.ms)
                  .slideY(begin: 0.06, end: 0),
            if (user != null) ...[
              const SizedBox(height: AppSizes.md),
              AccountStatusCard(user: user),
            ],
            const SizedBox(height: AppSizes.xl),
            // Each category opens to show its items, so the tab stays short.
            SettingsGroup(
              icon: AppIcons.work_outline_rounded,
              title: 'Business',
              summary: 'Services, portfolio, hours, public profile',
              children: [
                SettingsTile(icon: AppIcons.design_services_outlined, label: 'My Services', onTap: () => context.push('/my-services')),
                SettingsTile(icon: AppIcons.photo_library_outlined, label: 'Portfolio', onTap: () => context.push('/portfolio')),
                SettingsTile(icon: AppIcons.schedule_outlined, label: 'Availability', onTap: () => context.push('/availability')),
                SettingsTile(icon: AppIcons.calendar_month_outlined, label: 'Calendar', onTap: () => context.push('/calendar')),
                SettingsTile(
                  icon: AppIcons.visibility_outlined,
                  label: 'View public profile',
                  // Disabled until the profile has loaded: the preview needs its id.
                  onTap: provider == null ? null : () => context.push('/provider-preview/${provider.id}'),
                ),
              ],
            ),
            SettingsGroup(
              icon: AppIcons.payments_outlined,
              title: 'Earnings & reputation',
              summary: 'Earnings, commission, GCash, reviews, badges',
              children: [
                SettingsTile(icon: AppIcons.payments_outlined, label: 'Earnings', onTap: () => context.push('/earnings')),
                SettingsTile(icon: AppIcons.receipt_long_outlined, label: 'Commission', onTap: () => context.push('/commissions')),
                SettingsTile(icon: AppIcons.account_balance_wallet_rounded, label: 'GCash details', onTap: () => context.push('/gcash-details')),
                SettingsTile(icon: AppIcons.bar_chart_rounded, label: 'Statistics', onTap: () => context.push('/statistics')),
                SettingsTile(
                  icon: AppIcons.reviews_outlined,
                  label: 'Reviews',
                  onTap: provider == null ? null : () => context.push('/reviews/${provider.id}'),
                ),
                SettingsTile(icon: AppIcons.workspace_premium_outlined, label: 'My Badges', onTap: () => context.push('/provider-badges')),
              ],
            ),
            SettingsGroup(
              icon: AppIcons.person_outline_rounded,
              title: 'Account',
              summary: 'Profile, verification, password',
              children: [
                SettingsTile(icon: AppIcons.person_outline_rounded, label: 'Edit profile', onTap: () => context.push('/edit-profile')),
                SettingsTile(icon: AppIcons.badge_outlined, label: 'Identity verification', onTap: () => context.push('/identity-verification')),
                SettingsTile(icon: AppIcons.verified_user_outlined, label: 'Verification status', onTap: () => context.push('/verification-status')),
                SettingsTile(icon: AppIcons.lock_outline_rounded, label: 'Change password', onTap: () => context.push('/change-password')),
              ],
            ),
            SettingsGroup(
              icon: AppIcons.history_rounded,
              title: 'Activity',
              summary: 'Notifications, history, reports',
              children: [
                SettingsTile(icon: AppIcons.notifications_none_rounded, label: 'Notifications', onTap: () => context.push('/notifications')),
                SettingsTile(icon: AppIcons.history_rounded, label: 'Activity history', onTap: () => context.push('/activity-history')),
                SettingsTile(icon: AppIcons.flag_outlined, label: 'File a report', onTap: () => context.push('/file-report')),
                SettingsTile(icon: AppIcons.receipt_long_outlined, label: 'My reports', onTap: () => context.push('/my-reports')),
              ],
            ),
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
              summary: 'Support tickets, help center, policies',
              children: [
                SettingsTile(icon: AppIcons.support_agent_rounded, label: 'Support tickets', onTap: () => context.push('/support/tickets')),
                SettingsTile(icon: AppIcons.help_outline_rounded, label: 'Help Center', onTap: () => context.push('/help-center')),
                SettingsTile(icon: AppIcons.info_outline_rounded, label: 'About SkillServe', onTap: () => context.push('/about')),
                SettingsTile(icon: AppIcons.description_outlined, label: 'Terms & Conditions', onTap: () => context.push('/terms')),
                SettingsTile(icon: AppIcons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () => context.push('/privacy')),
                SettingsTile(icon: AppIcons.groups_outlined, label: 'Community Guidelines', onTap: () => context.push('/community-guidelines')),
              ],
            ),
            SettingsGroup(
              icon: AppIcons.description_outlined,
              title: 'Your data',
              summary: 'View or delete your account data',
              children: [
                SettingsTile(icon: AppIcons.description_outlined, label: 'View account data', onTap: () => context.push('/account-data')),
                SettingsTile(icon: AppIcons.delete_outline_rounded, label: 'Delete account', danger: true, onTap: () => context.push('/account-deletion')),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            SettingsSessionButton(
              signedIn: true,
              onPressed: () async {
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
            const SizedBox(height: AppSizes.lg),
          ],
        ),
      ),
    );
  }
}
