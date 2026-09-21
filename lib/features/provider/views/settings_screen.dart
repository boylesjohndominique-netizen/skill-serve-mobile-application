import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../profile/views/account_status_card.dart';

import '../../settings/controllers/preferences_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cards/profile_card.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/misc/status_badge.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../marketplace/models/provider_model.dart';
import '../services/provider_service_service.dart';

/// Provider's Profile tab — account, business tools, and preferences.
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

    int idx = 0;
    Widget stagger(Widget child) {
      final delay = Duration(milliseconds: 100 + (idx++) * 40);
      return child
          .animate()
          .fadeIn(delay: delay, duration: 300.ms)
          .slideX(begin: 0.04, end: 0);
    }

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
                    StatusBadge.fromStatus(provider?.verificationStatus ?? 'pending'),
              )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 350.ms)
                  .slideY(begin: 0.06, end: 0),
            if (user != null) ...[
              const SizedBox(height: AppSizes.md),
              AccountStatusCard(user: user),
            ],
            const SizedBox(height: AppSizes.xl),
            stagger(const _SectionLabel('Business')),
            stagger(_Tile(
                icon: AppIcons.design_services_outlined,
                label: 'My Services',
                onTap: () => context.push('/my-services'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.photo_library_outlined,
                label: 'Portfolio',
                onTap: () => context.push('/portfolio'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.bar_chart_rounded,
                label: 'Statistics',
                onTap: () => context.push('/statistics'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.calendar_month_outlined,
                label: 'Calendar',
                onTap: () => context.push('/calendar'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.schedule_outlined,
                label: 'Availability',
                onTap: () => context.push('/availability'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.reviews_outlined,
                label: 'Reviews',
                // Disabled until the profile has loaded: '/reviews/' with no id
                // opens nothing.
                onTap: provider == null ? null : () => context.push('/reviews/${provider.id}'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.payments_outlined,
                label: 'Earnings',
                onTap: () => context.push('/earnings'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.verified_user_outlined,
                label: 'Verification Status',
                onTap: () => context.push('/verification-status'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.workspace_premium_outlined,
                label: 'My Badges',
                onTap: () => context.push('/provider-badges'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.visibility_outlined,
                label: 'View public profile',
                // '/provider-profile-preview' never existed; the read-only
                // preview is the customer's view of this profile.
                onTap: provider == null ? null : () => context.push('/provider-preview/${provider.id}'),
                isDark: isDark)),
            const SizedBox(height: AppSizes.lg),
            stagger(const _SectionLabel('Account')),
            stagger(_Tile(
                icon: AppIcons.person_outline_rounded,
                label: 'Edit profile',
                onTap: () => context.push('/edit-profile'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.lock_outline_rounded,
                label: 'Change password',
                onTap: () => context.push('/change-password'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.notifications_none_rounded,
                label: 'Notifications',
                onTap: () => context.push('/notifications'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.history_rounded,
                label: 'Activity history',
                onTap: () => context.push('/activity-history'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.flag_outlined,
                label: 'File a report',
                onTap: () => context.push('/file-report'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.receipt_long_outlined,
                label: 'My reports',
                onTap: () => context.push('/my-reports'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.support_agent_rounded,
                label: 'Support tickets',
                onTap: () => context.push('/support/tickets'),
                isDark: isDark)),
            const SizedBox(height: AppSizes.lg),
            stagger(const _SectionLabel('Preferences')),
            stagger(_SwitchTile(
                icon: AppIcons.dark_mode_outlined,
                label: 'Dark mode',
                value: preferences.isDarkMode,
                onChanged: (_) async => preferences.toggleDarkMode(),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.notifications_none_rounded,
                label: 'Notification preferences',
                onTap: () => context.push('/notification-preferences'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.privacy_tip_outlined,
                label: 'Privacy settings',
                onTap: () => context.push('/privacy-settings'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.apps_rounded,
                label: 'Application preferences',
                onTap: () => context.push('/application-preferences'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.verified_user_outlined,
                label: 'Security activity',
                onTap: () => context.push('/security-activity'),
                isDark: isDark)),
            const SizedBox(height: AppSizes.lg),
            stagger(const _SectionLabel('Support')),
            stagger(_Tile(
                icon: AppIcons.help_outline_rounded,
                label: 'Help Center',
                onTap: () => context.push('/help-center'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.description_outlined,
                label: 'Terms & Conditions',
                onTap: () => context.push('/terms'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () => context.push('/privacy'),
                isDark: isDark)),
            stagger(_Tile(
                icon: AppIcons.groups_outlined,
                label: 'Community Guidelines',
                onTap: () => context.push('/community-guidelines'),
                isDark: isDark)),
            const SizedBox(height: AppSizes.xl),
            stagger(_Tile(
              icon: AppIcons.logout_rounded,
              label: 'Log out',
              danger: true,
              isDark: isDark,
              onTap: () async {
                final confirmed = await AppDialog.confirm(
                  context,
                  title: 'Log out?',
                  message:
                      'You\'ll need to log in again to manage bookings or your services.',
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
  final AppIconData icon;
  final String label;

  /// Null disables the tile (e.g. while the profile it needs is loading).
  final VoidCallback? onTap;
  final bool danger;
  final bool isDark;
  const _Tile(
      {required this.icon,
      required this.label,
      required this.onTap,
      this.danger = false,
      this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.error
        : (isDark ? AppColors.textOnDark : AppColors.textPrimary);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppIcon(icon,
          color: danger
              ? AppColors.error
              : (isDark ? AppColors.textMutedDark : AppColors.textSecondary),
          size: 21),
      title: Text(label, style: AppTextStyles.bodyLarge.copyWith(color: color)),
      trailing: danger
          ? null
          : AppIcon(AppIcons.chevron_right_rounded,
              color: isDark ? AppColors.neutral400 : AppColors.neutral300),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final AppIconData icon;
  final String label;
  final bool value;
  final void Function(bool) onChanged;
  final bool isDark;
  const _SwitchTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onChanged,
      this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppIcon(icon,
          color: isDark ? AppColors.textMutedDark : AppColors.textSecondary,
          size: 21),
      title: Text(label,
          style: AppTextStyles.bodyLarge.copyWith(
              color: isDark ? AppColors.textOnDark : AppColors.textPrimary)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}
