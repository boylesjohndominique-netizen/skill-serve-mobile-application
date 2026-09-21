import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/verification_seal.dart';
import '../controllers/verification_controller.dart';
import '../models/verification_document_model.dart';
import 'verification_upload_panel.dart';

/// The provider's verification: where the review stands, what the reviewer
/// said, the documents already sent, and — while allowed — the upload.
class VerificationStatusScreen extends StatelessWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VerificationController()..load(),
      child: const _VerificationStatusView(),
    );
  }
}

class _VerificationStatusView extends StatelessWidget {
  const _VerificationStatusView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VerificationController>();
    final verification = controller.verification;

    return Scaffold(
      appBar: AppBar(title: const Text('Verification Status')),
      body: SafeArea(
        child: controller.isLoading && verification == null
            ? const LoadingState()
            : verification == null
                ? ErrorState(
                    message: controller.errorMessage ?? 'Unable to load your verification status.',
                    onRetry: controller.load,
                  )
                : RefreshIndicator(
                    onRefresh: controller.load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSizes.pageHPad),
                      children: [
                        VerificationStatusHeader(verification: verification),
                        if (verification.request != null && verification.request!.documents.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.xxl),
                          Text('Submitted documents', style: AppTextStyles.titleLarge),
                          const SizedBox(height: AppSizes.md),
                          for (final document in verification.request!.documents)
                            _SubmittedDocument(document: document),
                        ],
                        if (verification.canSubmit) ...[
                          const SizedBox(height: AppSizes.xl),
                          Text(
                            verification.needsMoreInfo ? 'Send what was asked for' : 'Upload your documents',
                            style: AppTextStyles.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A government-issued ID is required; add certificates or licenses for your trade if you have them.',
                            style: AppTextStyles.bodySmall,
                          ),
                          const SizedBox(height: AppSizes.md),
                          const VerificationUploadPanel(),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
}

/// Seal, headline and the reviewer's message for the current status. Also
/// used by the onboarding flow's last step.
class VerificationStatusHeader extends StatelessWidget {
  final ProviderVerification verification;
  const VerificationStatusHeader({super.key, required this.verification});

  @override
  Widget build(BuildContext context) {
    final request = verification.request;
    final (seal, title, message) = switch (verification.status) {
      'verified' => ('verified', "You're verified!", 'Clients see your verified badge, and you can list services.'),
      'pending' => ('pending', 'Under review', 'Our admin team is reviewing your documents. We will notify you when they decide.'),
      'rejected' => ('rejected', 'Not approved', 'Your last submission was not approved. Upload new documents to try again.'),
      'additional_info_required' => ('resubmission_requested', 'More information needed', 'The reviewer asked for more. Send it below.'),
      _ => ('pending', 'Get verified', 'Upload a government-issued ID so clients know they can trust you. Verified providers can list services.'),
    };
    final reviewerNote = switch (verification.status) {
      'rejected' => request?.rejectionReason,
      'additional_info_required' => request?.additionalInfoRequest,
      _ => null,
    };

    return Column(
      children: [
        VerificationSeal(status: seal, size: 84, showLabel: true)
            .animate()
            .scale(duration: 500.ms, curve: Curves.easeOutBack)
            .fadeIn(),
        const SizedBox(height: AppSizes.lg),
        Text(title, style: AppTextStyles.headlineLarge, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        if (verification.isPending && request?.submittedAt != null) ...[
          const SizedBox(height: AppSizes.sm),
          Text('Submitted ${Formatters.dateShort(request!.submittedAt!)}', style: AppTextStyles.bodySmall),
        ],
        if (reviewerNote != null && reviewerNote.isNotEmpty) ...[
          const SizedBox(height: AppSizes.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: verification.isRejected ? AppColors.errorBg : AppColors.secondarySoft,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verification.isRejected ? 'Reason' : 'What the reviewer asked for',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: verification.isRejected ? AppColors.error : AppColors.secondaryDeep,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reviewerNote,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: verification.isRejected ? AppColors.error : AppColors.secondaryDeep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SubmittedDocument extends StatelessWidget {
  final VerificationDocumentModel document;
  const _SubmittedDocument({required this.document});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5), width: 0.8),
      ),
      child: Row(
        children: [
          AppIcon(
            document.type == 'government_id'
                ? AppIcons.badge_outlined
                : document.type == 'certificate'
                    ? AppIcons.workspace_premium_outlined
                    : AppIcons.description_outlined,
            size: 20,
            color: AppColors.secondaryDeep,
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(document.typeLabel, style: AppTextStyles.bodyLarge),
                Text(
                  document.fileName,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (document.createdAt != null)
            Text(Formatters.dateShort(document.createdAt!), style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
