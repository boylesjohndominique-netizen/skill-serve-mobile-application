import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/preferences_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/misc/app_icon.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = context.watch<PreferencesController>();
    return _PreferenceScaffold(
      title: 'Notification Preferences',
      intro: 'Choose which platform updates you want to receive.',
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
            subtitle: 'New messages and conversation updates',
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
            subtitle: 'Hide your profile from public discovery where supported',
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
    final theme = context.watch<ThemeController>();
    return _PreferenceScaffold(
      title: 'Application Preferences',
      intro: 'Configure the SkillServe experience on this device.',
      children: [
        _PreferenceSwitch(
            icon: AppIcons.dark_mode_outlined,
            title: 'Dark mode',
            subtitle: 'Use the dark visual theme',
            value: theme.mode == ThemeMode.dark,
            onChanged: (_) async => theme.toggle()),
        _PreferenceSwitch(
            icon: AppIcons.refresh_rounded,
            title: 'Reduce motion',
            subtitle: 'Prefer fewer animated transitions',
            value: preferences.reduceMotion,
            onChanged: preferences.setReduceMotion),
      ],
    );
  }
}

class _PreferenceScaffold extends StatelessWidget {
  final String title;
  final String intro;
  final List<Widget> children;

  const _PreferenceScaffold(
      {required this.title, required this.intro, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pageHPad),
        children: [
          Text(title, style: AppTextStyles.displayMedium),
          const SizedBox(height: AppSizes.sm),
          Text(intro, style: AppTextStyles.bodyLarge),
          const SizedBox(height: AppSizes.xl),
          ...children,
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
  final Future<void> Function(bool) onChanged;

  const _PreferenceSwitch(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          onChanged: onChanged,
        ),
      ),
    );
  }
}
