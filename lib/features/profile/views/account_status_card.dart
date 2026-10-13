import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/misc/status_badge.dart';
import '../../auth/models/user_model.dart';
import '../../../core/widgets/feedback/app_notice.dart';

/// The account's standing (M 2.4): active, and for providers the verification
/// state and any suspension an administrator applied (M 9.6).
class AccountStatusCard extends StatelessWidget {
  final UserModel user;
  const AccountStatusCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProvider = user.role == UserRole.provider;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Account status', user.status),
          if (isProvider && user.providerVerificationStatus != null) ...[
            const SizedBox(height: AppSizes.sm),
            _row('Verification', user.providerVerificationStatus!),
          ],
          if (isProvider && user.providerSuspended) ...[
            const SizedBox(height: AppSizes.md),
            AppNotice(
              tone: NoticeTone.error,
              icon: AppIcons.cancel_outlined,
              message: 'Your provider account is suspended: you are hidden from the marketplace and '
                  'cannot take new bookings.'
                  '${(user.providerSuspensionReason ?? '').isNotEmpty ? ' Reason: ${user.providerSuspensionReason}' : ''}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String status) => Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          StatusBadge.fromStatus(status),
        ],
      );
}
