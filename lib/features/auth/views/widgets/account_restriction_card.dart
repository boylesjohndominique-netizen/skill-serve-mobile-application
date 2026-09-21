import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/models/account_restriction.dart';
import '../../../../core/widgets/misc/app_icon.dart';

/// Why a suspended or banned account cannot sign in, with the administrator's
/// reason, when it ends, and a way to contact support (M 1.6, M 15.4).
class AccountRestrictionCard extends StatelessWidget {
  final AccountRestriction restriction;
  const AccountRestrictionCard({super.key, required this.restriction});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppIcon(AppIcons.cancel_outlined, color: AppColors.error, size: 20),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(restriction.title,
                      style: AppTextStyles.titleMedium.copyWith(color: AppColors.error)),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            if (restriction.reason != null && restriction.reason!.isNotEmpty) ...[
              Text('Reason: ${restriction.reason}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
              const SizedBox(height: 4),
            ],
            Text(restriction.explanation, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            const SizedBox(height: AppSizes.sm),
            TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, foregroundColor: AppColors.error),
              onPressed: () => context.push('/contact'),
              icon: const AppIcon(AppIcons.support_agent_rounded, size: 18, color: AppColors.error),
              label: const Text('Contact support'),
            ),
          ],
        ),
      ),
    );
  }
}
