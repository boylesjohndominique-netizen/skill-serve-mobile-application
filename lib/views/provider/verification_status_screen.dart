import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../data/mock/mock_data.dart';

class _DocRow {
  final String label;
  final String status;
  const _DocRow(this.label, this.status);
}

/// Shows the provider's ID/certificate review status — mirrors the
/// verification "seal" concept from the Admin Web Application.
class VerificationStatusScreen extends StatelessWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = MockData.providers.first;
    const docs = [
      _DocRow('Government-issued ID', 'approved'),
      _DocRow('Certificate of training', 'approved'),
      _DocRow('Proof of address', 'pending'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Verification Status')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: provider.isVerified ? AppColors.success : AppColors.warning,
                        width: 3,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Icon(
                      provider.isVerified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                      size: 38,
                      color: provider.isVerified ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    provider.isVerified ? 'You\'re verified!' : 'Verification in progress',
                    style: AppTextStyles.headlineLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.isVerified
                        ? 'Clients can see your verified badge across the platform.'
                        : 'Our admin team is reviewing your submitted documents.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xxl),
            Text('Submitted documents', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizes.md),
            for (final d in docs)
              Container(
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.radiusLg), border: Border.all(color: AppColors.line)),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 18, color: AppColors.neutral300),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(child: Text(d.label, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary))),
                    StatusBadge.fromStatus(d.status),
                  ],
                ),
              ),
            const SizedBox(height: AppSizes.xl),
            OutlinedAppButton(label: 'Resubmit a document', icon: Icons.upload_file_rounded, onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
