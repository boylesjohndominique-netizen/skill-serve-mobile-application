import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../controllers/identity_controller.dart';
import '../models/identity_verification_model.dart';

/// Why this account cannot currently book or take on work, and where to fix it.
///
/// `GET /api/client/v1/transaction-eligibility` is the one place the rule
/// lives; the app only renders the answer. Nothing is drawn while the account
/// is eligible, so this can sit on any screen unconditionally.
///
/// Showing this is what turns a bare 403 at the moment of booking into
/// something the user can act on before they get there.
class EligibilityBanner extends StatefulWidget {
  const EligibilityBanner({super.key});

  @override
  State<EligibilityBanner> createState() => _EligibilityBannerState();
}

class _EligibilityBannerState extends State<EligibilityBanner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<IdentityController>().refreshEligibility();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eligibility = context.watch<IdentityController>().eligibility;
    if (eligibility.eligible) return const SizedBox.shrink();

    final prompt = _promptFor(eligibility);
    if (prompt == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      // The banner owns the space below it, so an eligible account renders
      // nothing at all rather than an empty gap on the screen that hosts it.
      // Every host already has a gap above. Outside the InkWell, so the tap
      // ripple stops at the card rather than bleeding into the gap.
      padding: const EdgeInsets.only(bottom: AppSizes.lg),
      child: Semantics(
        button: true,
        label: '${prompt.title}. ${prompt.message}',
        child: InkWell(
          onTap: () => context.push(prompt.route),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceAltDark : prompt.background,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: prompt.tint.withValues(alpha: 0.35), width: 0.8),
            ),
            child: Row(
              children: [
                AppIcon(prompt.icon, color: prompt.tint, size: AppSizes.iconMd),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prompt.title,
                          style: AppTextStyles.titleMedium.copyWith(color: prompt.tint)),
                      const SizedBox(height: 2),
                      Text(prompt.message, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                AppIcon(AppIcons.chevron_right_rounded,
                    color: prompt.tint, size: AppSizes.iconMd),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// What to say and where to send them, per the API's `reason`. An unknown
  /// reason draws nothing rather than a banner that leads nowhere useful.
  _EligibilityPrompt? _promptFor(TransactionEligibility eligibility) {
    return switch (eligibility.reason) {
      'identity_unverified' => const _EligibilityPrompt(
          title: 'Verify your identity',
          message: 'Submit your Philippine National ID to start booking and working.',
          route: '/identity-verification',
          icon: AppIcons.badge_outlined,
          tint: AppColors.warning,
          background: AppColors.warningBg,
        ),
      'identity_pending' => const _EligibilityPrompt(
          title: 'National ID under review',
          message: 'We are checking your ID. You can transact as soon as it is approved.',
          route: '/identity-verification',
          icon: AppIcons.hourglass_top_rounded,
          tint: AppColors.info,
          background: AppColors.infoBg,
        ),
      'identity_rejected' => const _EligibilityPrompt(
          title: 'National ID not accepted',
          message: 'Have a look at why, then send it again.',
          route: '/identity-verification',
          icon: AppIcons.info_outline_rounded,
          tint: AppColors.error,
          background: AppColors.errorBg,
        ),
      'outstanding_commission' => _EligibilityPrompt(
          title: 'Commission outstanding',
          message: 'You owe ₱${eligibility.outstandingTotal}. Settle it to take on new work.',
          route: '/commissions',
          icon: AppIcons.receipt_long_outlined,
          tint: AppColors.error,
          background: AppColors.errorBg,
        ),
      'no_provider_profile' => const _EligibilityPrompt(
          title: 'Finish setting up your business',
          message: 'Complete your provider profile before you can take bookings.',
          route: '/provider-onboarding',
          icon: AppIcons.work_outline_rounded,
          tint: AppColors.warning,
          background: AppColors.warningBg,
        ),
      _ => null,
    };
  }
}

class _EligibilityPrompt {
  final String title;
  final String message;
  final String route;
  final AppIconData icon;
  final Color tint;
  final Color background;

  const _EligibilityPrompt({
    required this.title,
    required this.message,
    required this.route,
    required this.icon,
    required this.tint,
    required this.background,
  });
}
