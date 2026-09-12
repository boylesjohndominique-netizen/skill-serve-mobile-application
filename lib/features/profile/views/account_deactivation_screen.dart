import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/buttons/danger_button.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../profile/services/account_data_service.dart';

/// PDF §15.2 — Request Account Deactivation
///
/// Allows users to request deactivation of their account according to
/// platform procedures. No client API endpoint is documented; the
/// deactivation request is mock-only.
class AccountDeactivationScreen extends StatefulWidget {
  const AccountDeactivationScreen({super.key});

  @override
  State<AccountDeactivationScreen> createState() =>
      _AccountDeactivationScreenState();
}

class _AccountDeactivationScreenState extends State<AccountDeactivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Deactivate account?',
      message:
          'Your account will be deactivated. You will not be able to book '
          'or message providers until you contact support to reactivate.',
      confirmLabel: 'Deactivate',
      danger: true,
    );
    if (!confirmed) return;

    setState(() => _isSubmitting = true);
    try {
      await AccountDataService().requestDeactivation(
        reason: _reasonController.text.trim(),
      );
      if (mounted) {
        await AppDialog.confirm(
          context,
          title: 'Request submitted',
          message:
              'Your deactivation request has been received. Our team will '
              'process it within 48 hours.',
          confirmLabel: 'OK',
        );
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Deactivate Account')),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIcon(AppIcons.warning_amber_rounded,
                      size: 22, color: AppColors.error),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Before you deactivate',
                            style: AppTextStyles.titleMedium
                                .copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          'Deactivating your account will hide your profile and '
                          'prevent new bookings. Existing bookings will be '
                          'honored. Contact support to reactivate.',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textSecondary),
                        ),
                      ],
                    ),
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
                  Text('Reason for deactivation',
                      style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppSizes.sm),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Help us understand why (optional)',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textSecondary),
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
              label: _isSubmitting ? 'Submitting…' : 'Deactivate Account',
              onPressed: _isSubmitting ? null : _submit,
            ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
            const SizedBox(height: AppSizes.xxl),
          ],
        ),
      ),
    );
  }
}
