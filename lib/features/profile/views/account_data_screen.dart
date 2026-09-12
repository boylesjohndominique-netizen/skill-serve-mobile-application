import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// PDF §15.1 — View Account Data
///
/// Displays the personal account information maintained by the platform.
/// Live mode reads from GET /api/client/v1/auth/me; mock mode returns
/// the current session user.
class AccountDataScreen extends StatelessWidget {
  const AccountDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Account Data')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Text('Your Account Information',
                    style: AppTextStyles.headlineMedium)
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.06, end: 0),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Review the personal information maintained by SkillServe for your account.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: isDark ? AppColors.textMutedDark : AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.xl),
            if (user != null) ...[
              _DataSection(
                title: 'Personal Details',
                items: [
                  _DataItem(label: 'Full Name', value: user.fullName),
                  _DataItem(label: 'Email', value: user.email),
                  _DataItem(label: 'Phone', value: user.phone.isEmpty ? '—' : user.phone),
                  _DataItem(label: 'Address', value: user.address.isEmpty ? '—' : user.address),
                ],
                isDark: isDark,
              ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
              const SizedBox(height: AppSizes.lg),
              _DataSection(
                title: 'Account Information',
                items: [
                  _DataItem(label: 'Account Type', value: user.role.name.toUpperCase()),
                  _DataItem(label: 'Account Status', value: user.status.toUpperCase()),
                  _DataItem(
                    label: 'Member Since',
                    value: Formatters.dateShort(user.createdAt),
                  ),
                  _DataItem(label: 'User ID', value: user.id),
                ],
                isDark: isDark,
              ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
            ] else
              const _NoUserCard(),
            const SizedBox(height: AppSizes.xl),
            _InfoNote(
              isDark: isDark,
            ).animate().fadeIn(delay: 300.ms, duration: 350.ms),
            const SizedBox(height: AppSizes.xxl),
          ],
        ),
      ),
    );
  }
}

class _DataSection extends StatelessWidget {
  final String title;
  final List<_DataItem> items;
  final bool isDark;
  const _DataSection({required this.title, required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.sm),
            child: Text(title, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
          ),
          const Divider(height: 1),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: AppSizes.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      items[i].label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.textMutedDark : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Text(
                      items[i].value,
                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DataItem {
  final String label;
  final String value;
  const _DataItem({required this.label, required this.value});
}

class _NoUserCard extends StatelessWidget {
  const _NoUserCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        children: [
          const AppIcon(AppIcons.info_outline_rounded, size: 32, color: AppColors.textSecondary),
          const SizedBox(height: AppSizes.md),
          Text('No account data available', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSizes.sm),
          Text('Log in to view your account information.', style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  final bool isDark;
  const _InfoNote({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(AppIcons.info_outline_rounded, size: 18, color: AppColors.secondary),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              'This information is maintained by the SkillServe platform. '
              'Contact support to request corrections.',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.textMutedDark : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
