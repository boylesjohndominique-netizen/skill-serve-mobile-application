import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/buttons/danger_button.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../profile/services/account_data_service.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/theme/app_palette.dart';

/// PDF §15.3 — Request Account Deletion
///
/// Allows users to request deletion of their account and eligible
/// associated data subject to applicable platform rules.
/// Deletes the account through DELETE /api/client/v1/auth/me.
class AccountDeletionScreen extends StatefulWidget {
  const AccountDeletionScreen({super.key});

  @override
  State<AccountDeletionScreen> createState() => _AccountDeletionScreenState();
}

class _AccountDeletionScreenState extends State<AccountDeletionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Delete account?',
      message:
          'Your account is closed immediately and you are signed out of every '
          'device. Contact support if you change your mind — an administrator '
          'can restore it.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!confirmed) return;

    setState(() => _isSubmitting = true);
    try {
      await AccountDataService().deleteAccount(
        password: _passwordController.text,
        reason: _reasonController.text.trim(),
      );
      if (!mounted) return;

      // The API has already revoked every token, so the local session is
      // cleared rather than logged out over the network.
      await context.read<AuthController>().logout();
      if (mounted) {
        AppSnackbar.success(context, 'Your account has been deleted.');
        context.go('/welcome');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        // The API explains why: a wrong password, or bookings still open.
        AppSnackbar.error(
            context, apiErrorMessage(e, 'Unable to delete your account right now.'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Delete Account')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.2),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppIcon(AppIcons.warning_amber_rounded,
                          size: 22, color: AppColors.error),
                      const SizedBox(width: AppSizes.sm),
                      Text('You will lose access to your account',
                          style: AppTextStyles.titleMedium
                              .copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Deleting your account signs you out everywhere and closes '
                    'your access to:',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textMutedDark
                            : context.textSecondaryColor),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _BulletPoint('Profile and personal information', isDark: isDark),
                  _BulletPoint('Booking history and reviews', isDark: isDark),
                  _BulletPoint('Messages and conversations', isDark: isDark),
                  _BulletPoint('Saved preferences and favorites', isDark: isDark),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Settle or cancel any open bookings first — we will not close '
                    'an account that still owes someone a job. Want a copy of '
                    'your data? Take it from "View account data" before you go.',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textMutedDark
                            : context.textSecondaryColor),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms),
            const SizedBox(height: AppSizes.xl),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason for deletion', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSizes.sm),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Help us improve (optional)',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textMutedDark
                              : context.textSecondaryColor),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Text('Confirm password', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSizes.sm),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Password is required to confirm deletion'
                        : null,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textMutedDark
                              : context.textSecondaryColor),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                      ),
                    ),
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
            const SizedBox(height: AppSizes.xl),
            DangerButton(
              label: _isSubmitting ? 'Deleting…' : 'Delete My Account',
              onPressed: _isSubmitting ? null : _submit,
            ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
            const SizedBox(height: AppSizes.xxl),
          ],
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  final bool isDark;
  const _BulletPoint(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                  color: isDark ? AppColors.textMutedDark : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
