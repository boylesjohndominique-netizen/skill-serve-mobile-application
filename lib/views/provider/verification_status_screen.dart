import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

/// Shows the provider's ID/certificate review status.
class VerificationStatusScreen extends StatelessWidget {
  const VerificationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = MockData.providers.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                      ),
                    ),
                    child: Icon(
                      provider.isVerified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                      size: 38,
                      color: provider.isVerified ? AppColors.success : AppColors.warning,
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    provider.isVerified ? 'You\'re verified!' : 'Verification in progress',
                    style: AppTextStyles.headlineLarge,
                  ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 4),
                  Text(
                    provider.isVerified
                        ? 'Clients can see your verified badge across the platform.'
                        : 'Our admin team is reviewing your submitted documents.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xxl),
            Text('Submitted documents', style: AppTextStyles.titleLarge)
                .animate().fadeIn(delay: 350.ms, duration: 300.ms),
            const SizedBox(height: AppSizes.md),
            for (var i = 0; i < docs.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5), width: 0.8),
                  boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, size: 18, color: AppColors.neutral300),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(child: Text(docs[i].label, style: AppTextStyles.bodyLarge)),
                    StatusBadge.fromStatus(docs[i].status),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 400 + i * 80), duration: 350.ms)
                  .slideX(begin: 0.06, end: 0),
            const SizedBox(height: AppSizes.xl),
            OutlinedAppButton(label: 'Resubmit a document', icon: Icons.upload_file_rounded, onPressed: () {})
                .animate().fadeIn(delay: 650.ms, duration: 350.ms),
          ],
        ),
      ),
    );
  }
}
