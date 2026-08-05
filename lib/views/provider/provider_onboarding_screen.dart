import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/inputs/app_text_field.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../core/widgets/misc/verification_seal.dart';
import '../../data/mock/mock_data.dart';
import '../../models/verification_document_model.dart';

/// P2 — Provider onboarding & verification gate.
/// Step 1: professional profile · Step 2: upload documents ·
/// Step 3: verification status seal.
class ProviderOnboardingScreen extends StatefulWidget {
  const ProviderOnboardingScreen({super.key});

  @override
  State<ProviderOnboardingScreen> createState() => _ProviderOnboardingScreenState();
}

class _ProviderOnboardingScreenState extends State<ProviderOnboardingScreen> {
  final _bioController = TextEditingController();
  int _yearsExperience = 3;
  String _category = MockData.categories.first.name;

  int _step = 0;
  late final List<VerificationDocumentModel> _docs = [...MockData.verificationDocs];

  bool get _verified => _docs.every((d) => d.status == 'approved');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Verified'),
        leading: _step > 0
            ? IconButton(onPressed: () => setState(() => _step--), icon: const Icon(Icons.arrow_back_rounded))
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSizes.md),
            _OnboardStepper(current: _step, names: const ['Profile', 'Documents', 'Status'])
                .animate().fadeIn(duration: 300.ms),
            const SizedBox(height: AppSizes.md),
            Expanded(
              child: AnimatedSwitcher(
                duration: AppAnimations.md,
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(AppSizes.pageHPad, 0, AppSizes.pageHPad, AppSizes.xl),
                  child: _buildStep(context),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.pageHPad, AppSizes.sm, AppSizes.pageHPad, AppSizes.lg),
          child: _step < 2
              ? PrimaryButton(
                  label: _step == 0 ? 'Continue' : 'Submit for review',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: () => setState(() => _step++),
                )
              : PrimaryButton(
                  label: _verified ? 'Go to dashboard' : 'Continue to dashboard',
                  icon: Icons.home_rounded,
                  onPressed: () => context.go('/provider'),
                ),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 0:
        return _stepProfile(context);
      case 1:
        return _stepDocuments(context);
      default:
        return _stepStatus(context);
    }
  }

  // ── Step 1: professional profile ──
  Widget _stepProfile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tell clients about yourself', style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text('This helps clients trust you before they book.', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSizes.lg),
        AppTextField(
          label: 'Professional bio',
          hint: 'Your experience, specialities, service areas…',
          controller: _bioController,
          maxLines: 4,
        ),
        const SizedBox(height: AppSizes.lg),
        Text('Years of experience', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSizes.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: _yearsExperience > 1 ? () => setState(() => _yearsExperience--) : null,
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: AppColors.secondary,
              ),
              Expanded(
                child: Text(
                  '$_yearsExperience ${_yearsExperience == 1 ? 'year' : 'years'}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.monoLg.copyWith(color: AppColors.secondary),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _yearsExperience++),
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        Text('Service category', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < MockData.categories.length; i++)
              ChoiceChip(
                label: Text(MockData.categories[i].name),
                selected: _category == MockData.categories[i].name,
                selectedColor: AppColors.secondary,
                labelStyle: AppTextStyles.label.copyWith(
                  color: _category == MockData.categories[i].name ? Colors.white : null,
                  fontWeight: FontWeight.w600,
                ),
                showCheckmark: false,
                onSelected: (_) => setState(() => _category = MockData.categories[i].name),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 150 + i * 50), duration: 300.ms)
                  .slideY(begin: 0.06, end: 0),
          ],
        ),
      ],
    );
  }

  // ── Step 2: upload documents ──
  Widget _stepDocuments(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upload your documents', style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text('Submit a government ID, certificate, or supporting document for review.', style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSizes.lg),
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
                      Text(_docs[i].label, style: AppTextStyles.titleMedium),
                      Text(_docs[i].type, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                StatusBadge.fromStatus(_docs[i].status),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: Duration(milliseconds: 120 + i * 70), duration: 350.ms)
              .slideX(begin: 0.05, end: 0),
        const SizedBox(height: AppSizes.md),
        OutlinedAppButton(
          label: 'Add a document',
          icon: Icons.upload_file_rounded,
          onPressed: _pickDocType,
        ).animate().fadeIn(delay: 350.ms, duration: 300.ms),
      ],
    );
  }

  Future<void> _pickDocType() async {
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
              Text('Add a document', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSizes.md),
              for (final t in ['ID', 'Certificate', 'Document'])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    t == 'ID' ? Icons.badge_outlined : (t == 'Certificate' ? Icons.workspace_premium_outlined : Icons.description_outlined),
                    color: AppColors.secondary,
                  ),
                  title: Text(t, style: AppTextStyles.bodyLarge),
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
      _docs.add(VerificationDocumentModel(
        id: 'VD-${DateTime.now().millisecondsSinceEpoch}',
        providerId: MockData.currentProvider.id,
        type: type,
        label: '${type == 'ID' ? 'Government-issued' : type == 'Certificate' ? 'Certificate of' : 'Supporting'} document',
        status: 'pending',
        submittedAt: DateTime.now(),
      ));
      MockData.verificationDocs.add(_docs.last);
    });
    AppSnackbar.success(context, 'Document submitted for review.');
  }

  // ── Step 3: status seal ──
  Widget _stepStatus(BuildContext context) {
    return Center(
      child: Column(
        children: [
          VerificationSeal(
            status: _verified ? 'verified' : 'pending',
            size: 84,
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
          const SizedBox(height: AppSizes.lg),
          Text(
            _verified ? 'You\'re verified!' : 'Under review',
            style: AppTextStyles.headlineLarge,
          ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
          const SizedBox(height: AppSizes.sm),
          Text(
            _verified
                ? 'Your documents are approved. You can now list services and start earning.'
                : 'Our admin team is reviewing your submitted documents. We\'ll notify you the moment your status changes.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ).animate().fadeIn(delay: 300.ms, duration: 350.ms),
          const SizedBox(height: AppSizes.xl),
          if (!_verified)
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      'You can still explore the app while verification is in progress.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms, duration: 350.ms),
        ],
      ),
    );
  }
}

class _OnboardStepper extends StatelessWidget {
  final int current;
  final List<String> names;

  const _OnboardStepper({required this.current, required this.names});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad),
      child: Row(
        children: [
          for (var i = 0; i < names.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: i <= current ? AppColors.secondary : AppColors.neutral100,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: AppAnimations.md,
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= current ? AppColors.secondary : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt),
                    border: Border.all(color: i <= current ? AppColors.secondary : AppColors.neutral200, width: 1.2),
                  ),
                  child: Center(
                    child: i < current
                        ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: AppTextStyles.label.copyWith(
                              color: i <= current ? Colors.white : AppColors.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(names[i], style: AppTextStyles.caption.copyWith(
                  color: i <= current ? AppColors.secondary : AppColors.textMuted,
                  fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                )),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
