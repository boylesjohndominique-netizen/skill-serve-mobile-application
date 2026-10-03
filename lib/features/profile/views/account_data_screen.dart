import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../services/account_data_service.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/buttons/outlined_app_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// View the account's data, and take a copy of it.
///
/// The summary on screen comes from the session (GET /api/client/v1/auth/me);
/// "Copy my data" pulls the full export, which also covers bookings, reviews,
/// reports and support tickets.
class AccountDataScreen extends StatefulWidget {
  const AccountDataScreen({super.key});

  @override
  State<AccountDataScreen> createState() => _AccountDataScreenState();
}

class _AccountDataScreenState extends State<AccountDataScreen> {
  bool _exporting = false;

  /// There is no file picker or share sheet in this app, so the export goes to
  /// the clipboard as indented JSON — no extra dependency, and the person can
  /// paste it wherever they keep their records.
  Future<void> _copyData() async {
    setState(() => _exporting = true);
    try {
      final json = await AccountDataService().exportAccountDataAsJson();
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        AppSnackbar.success(context, 'Your data was copied to the clipboard.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, apiErrorMessage(e, 'Unable to export your data.'));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

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
            if (user != null)
              OutlinedAppButton(
                label: _exporting ? 'Preparing…' : 'Copy my data',
                icon: AppIcons.description_outlined,
                onPressed: _exporting ? null : _copyData,
              ).animate().fadeIn(delay: 260.ms, duration: 350.ms),
            const SizedBox(height: AppSizes.md),
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
        color: context.surfaceAltColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        children: [
          AppIcon(AppIcons.info_outline_rounded, size: 32, color: context.textSecondaryColor),
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
          AppIcon(AppIcons.info_outline_rounded, size: 18, color: context.accentInk),
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
