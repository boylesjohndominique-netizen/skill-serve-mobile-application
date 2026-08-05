import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../core/widgets/misc/verification_seal.dart';
import '../../data/mock/mock_data.dart';
import '../../models/verification_document_model.dart';

/// Shows the provider's ID/certificate review status with the signature
/// VerificationSeal and document upload flow.
class VerificationStatusScreen extends StatefulWidget {
  const VerificationStatusScreen({super.key});

  @override
  State<VerificationStatusScreen> createState() => _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  late List<VerificationDocumentModel> _docs;

  @override
  void initState() {
    super.initState();
    _docs = [...MockData.verificationDocs];
  }

  bool get _verified => _docs.every((d) => d.status == 'approved');
  bool get _hasRejected => _docs.any((d) => d.status == 'rejected' || d.status == 'resubmission_requested');

  Future<void> _uploadDoc() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upload a document', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSizes.md),
              for (final t in ['ID', 'Certificate', 'Document'])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    t == 'ID' ? Icons.badge_outlined : (t == 'Certificate' ? Icons.workspace_premium_outlined : Icons.description_outlined),
                    color: AppColors.secondary,
                  ),
                  title: Text(t, style: AppTextStyles.bodyLarge),
                  subtitle: const Text('Photo or PDF'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.neutral300),
                  onTap: () => Navigator.of(context).pop(t),
                ),
            ],
          ),
        ),
      ),
    );
    if (type == null || !mounted) return;
    setState(() {
      final doc = VerificationDocumentModel(
        id: 'VD-${DateTime.now().millisecondsSinceEpoch}',
        providerId: MockData.currentProvider.id,
        type: type,
        label: '${type == 'ID' ? 'Government-issued' : type == 'Certificate' ? 'Certificate of' : 'Supporting'} document',
        status: 'pending',
        submittedAt: DateTime.now(),
      );
      _docs.add(doc);
      MockData.verificationDocs.add(doc);
    });
    AppSnackbar.success(context, 'Document submitted for review.');
  }

  Future<void> _resubmit() async {
    setState(() {
      for (var i = 0; i < _docs.length; i++) {
        if (_docs[i].status == 'rejected' || _docs[i].status == 'resubmission_requested') {
          _docs[i] = VerificationDocumentModel(
            id: _docs[i].id,
            providerId: _docs[i].providerId,
            type: _docs[i].type,
            label: _docs[i].label,
            status: 'pending',
            submittedAt: DateTime.now(),
          );
        }
      }
      // Keep the shared mock source in sync so the state survives navigation.
      MockData.verificationDocs.clear();
      MockData.verificationDocs.addAll(_docs);
    });
    AppSnackbar.success(context, 'Documents resubmitted for review.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Verification Status')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Center(
              child: Column(
                children: [
                  VerificationSeal(
                    status: _verified ? 'verified' : 'pending',
                    size: 84,
                    showLabel: true,
                  ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
                  const SizedBox(height: AppSizes.lg),
                  Text(
                    _verified ? 'You\'re verified!' : 'Verification in progress',
                    style: AppTextStyles.headlineLarge,
                  ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 4),
                  Text(
                    _verified
                        ? 'Clients can see your verified badge across the platform.'
                        : 'Our admin team is reviewing your submitted documents.',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 250.ms, duration: 300.ms),
                ],
              ),
            ),
            if (_hasRejected) ...[
              const SizedBox(height: AppSizes.xl),
              Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Action needed', style: AppTextStyles.titleMedium.copyWith(color: AppColors.error)),
                    const SizedBox(height: 4),
                    Text(
                      'One or more documents need a new copy. Please re-submit a clearer photo.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                    ),
                    const SizedBox(height: AppSizes.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _resubmit,
                        style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                        child: Text('Resubmit', style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 350.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
            ],
            const SizedBox(height: AppSizes.xxl),
            Text('Submitted documents', style: AppTextStyles.titleLarge)
                .animate().fadeIn(delay: 400.ms, duration: 300.ms),
            const SizedBox(height: AppSizes.md),
            for (var i = 0; i < _docs.length; i++)
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _docs[i].status == 'approved' ? AppColors.successBg : AppColors.warningBg,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Icon(
                        _docs[i].type == 'ID'
                            ? Icons.badge_outlined
                            : (_docs[i].type == 'Certificate' ? Icons.workspace_premium_outlined : Icons.description_outlined),
                        size: 17,
                        color: _docs[i].status == 'approved' ? AppColors.success : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_docs[i].label, style: AppTextStyles.bodyLarge),
                          Text(_docs[i].type, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    StatusBadge.fromStatus(_docs[i].status),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 450 + i * 70), duration: 350.ms)
                  .slideX(begin: 0.06, end: 0),
            const SizedBox(height: AppSizes.xl),
            OutlinedAppButton(
              label: 'Upload a document',
              icon: Icons.upload_file_rounded,
              onPressed: _uploadDoc,
            ).animate().fadeIn(delay: 700.ms, duration: 350.ms),
          ],
        ),
      ),
    );
  }
}
