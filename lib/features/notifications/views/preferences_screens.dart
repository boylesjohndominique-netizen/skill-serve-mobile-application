import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../settings/controllers/preferences_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/app_icon.dart';

/// The three Settings sub-screens. All of them read one account-scoped
/// [PreferencesController], so a change made on any of them is stored
/// server-side and follows the user to their other devices.

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesController>();
    return _PreferenceScaffold(
      title: 'Notification Preferences',
      intro:
          'Choose which platform updates you want to receive. Switching one off stops it being sent, on every device.',
      children: [
        _PreferenceSwitch(
            icon: AppIcons.calendar_month_rounded,
            title: 'Booking updates',
            subtitle: 'Requests, confirmations, changes, and cancellations',
            value: preferences.bookingNotifications,
            onChanged: preferences.setBookingNotifications),
        _PreferenceSwitch(
            icon: AppIcons.design_services_outlined,
            title: 'Service updates',
            subtitle: 'Service approvals, availability, and provider updates',
            value: preferences.serviceNotifications,
            onChanged: preferences.setServiceNotifications),
        _PreferenceSwitch(
            icon: AppIcons.chat_bubble_rounded,
            title: 'Messages',
            subtitle: 'New messages, conversation and support replies',
            value: preferences.messageNotifications,
            onChanged: preferences.setMessageNotifications),
        _PreferenceSwitch(
            icon: AppIcons.notifications_rounded,
            title: 'Announcements',
            subtitle: 'Platform news and administrator announcements',
            value: preferences.announcementNotifications,
            onChanged: preferences.setAnnouncementNotifications),
      ],
    );
  }
}

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesController>();
    return _PreferenceScaffold(
      title: 'Privacy Settings',
      intro: 'Control how your profile and activity are used in the app.',
      children: [
        _PreferenceSwitch(
            icon: AppIcons.visibility_outlined,
            title: 'Private profile',
            subtitle:
                'Hide your profile and services from search and browsing',
            value: preferences.privateProfile,
            onChanged: preferences.setPrivateProfile),
        _PreferenceSwitch(
            icon: AppIcons.search_rounded,
            title: 'Personalized discovery',
            subtitle: 'Use your activity to improve service suggestions',
            value: preferences.activityPersonalization,
            onChanged: preferences.setActivityPersonalization),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const AppIcon(AppIcons.privacy_tip_outlined),
          title: const Text('Privacy Policy'),
          subtitle:
              const Text('Review how SkillServe handles account information'),
          trailing: const AppIcon(AppIcons.chevron_right_rounded),
          onTap: () => context.push('/privacy'),
        ),
      ],
    );
  }
}

class ApplicationPreferencesScreen extends StatelessWidget {
  const ApplicationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesController>();
    return _PreferenceScaffold(
      title: 'Application Preferences',
      intro: 'Configure the SkillServe experience.',
      children: [
        _ThemeSelector(
          value: preferences.themeMode,
          enabled: !preferences.isSaving,
          onChanged: preferences.setThemeMode,
        ),
        const SizedBox(height: AppSizes.md),
        _PreferenceSwitch(
            icon: AppIcons.refresh_rounded,
            title: 'Reduce motion',
            subtitle: 'Remove animated transitions across the app',
            value: preferences.reduceMotion,
            onChanged: preferences.setReduceMotion),
      ],
    );
  }
}

/// Shared shell: title, intro, and the loading / error / content states the
/// screens share.
class _PreferenceScaffold extends StatelessWidget {
  final String title;
  final String intro;
  final List<Widget> children;

  const _PreferenceScaffold(
      {required this.title, required this.intro, required this.children});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesController>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: RefreshIndicator(
        onRefresh: preferences.refresh,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Text(title, style: AppTextStyles.displayMedium),
            const SizedBox(height: AppSizes.sm),
            Text(intro, style: AppTextStyles.bodyLarge),
            const SizedBox(height: AppSizes.xl),
            if (preferences.errorMessage != null) ...[
              _PreferenceNotice(
                message: preferences.errorMessage!,
                onRetry: preferences.refresh,
              ),
              const SizedBox(height: AppSizes.lg),
            ],
            if (preferences.isLoading)
              ...List.generate(
                children.length,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: AppSizes.sm),
                  child: ShimmerPlaceholder(height: 72),
                ),
              )
            else
              ...children,
          ],
        ),
      ),
    );
  }
}

/// Inline, non-blocking notice: the cached settings are still shown and
/// usable, so this explains rather than replaces them.
class _PreferenceNotice extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _PreferenceNotice({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          const AppIcon(AppIcons.error_rounded, size: 20),
          const SizedBox(width: AppSizes.sm),
          Expanded(child: Text(message, style: AppTextStyles.bodySmall)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Light / dark / system, as a segmented control rather than a switch —
/// "system" is a real choice and a two-state switch cannot express it.
class _ThemeSelector extends StatelessWidget {
  final ThemeMode value;
  final bool enabled;
  final Future<bool> Function(ThemeMode) onChanged;

  const _ThemeSelector(
      {required this.value, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(AppIcons.dark_mode_outlined,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textSecondary),
              const SizedBox(width: AppSizes.md),
              Text('Appearance', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text('Use the light or dark theme, or follow your device setting.',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSizes.md),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined)),
              ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined)),
              ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.phone_android_outlined)),
            ],
            selected: {value},
            showSelectedIcon: false,
            onSelectionChanged: enabled
                ? (selection) => onChanged(selection.first)
                : null,
          ),
        ],
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  final AppIconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Future<bool> Function(bool) onChanged;

  const _PreferenceSwitch(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preferences = context.watch<PreferencesController>();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          secondary: AppIcon(icon,
              color:
                  isDark ? AppColors.textMutedDark : AppColors.textSecondary),
          title: Text(title, style: AppTextStyles.titleMedium),
          subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
          value: value,
          // One save at a time: a second toggle mid-request would race the
          // rollback of the first.
          onChanged: preferences.isSaving
              ? null
              : (next) async {
                  final saved = await onChanged(next);
                  if (!context.mounted || saved) return;
                  AppSnackbar.error(
                      context,
                      preferences.errorMessage ??
                          'We could not save that change.');
                },
        ),
      ),
    );
  }
}
