import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/status_badge.dart';

class SecurityNotificationsScreen extends StatelessWidget {
  const SecurityNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final signedIn = auth.currentUser != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Security Activity')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.pageHPad),
        children: [
          Text('Security Activity', style: AppTextStyles.displayMedium),
          const SizedBox(height: AppSizes.sm),
          Text('Review important account and session events on this device.',
              style: AppTextStyles.bodyLarge),
          const SizedBox(height: AppSizes.xl),
          _SecurityEvent(
            icon: signedIn
                ? AppIcons.verified_user_rounded
                : AppIcons.lock_outline_rounded,
            title: signedIn
                ? 'Authenticated session active'
                : 'No authenticated session',
            detail: signedIn
                ? 'Protected features are available only while this session is valid.'
                : 'Sign in again to access protected account information.',
            badge: StatusBadge.fromStatus(signedIn ? 'active' : 'closed'),
          ),
          if (auth.sessionExpired)
            const _SecurityEvent(
              icon: AppIcons.warning_amber_rounded,
              title: 'Signed out by the server',
              detail:
                  'Your session was ended on the server — for example after a password change or an account action — so you need to sign in again.',
            ),
          const _SecurityEvent(
            icon: AppIcons.privacy_tip_outlined,
            title: 'Credential handling',
            detail:
                'You stay signed in on this device until you sign out. Your password is never stored — only a session token that the server can revoke.',
          ),
        ],
      ),
    );
  }
}

class _SecurityEvent extends StatelessWidget {
  final AppIconData icon;
  final String title;
  final String detail;
  final Widget? badge;

  const _SecurityEvent(
      {required this.icon,
      required this.title,
      required this.detail,
      this.badge});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon(icon, color: AppColors.secondary, size: 24),
            const SizedBox(width: AppSizes.md),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 5),
                  Text(detail, style: AppTextStyles.bodyMedium),
                  if (badge != null) ...[const SizedBox(height: 8), badge!],
                ])),
          ],
        ),
      ),
    );
  }
}
