import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/buttons/outlined_app_button.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import 'package:provider/provider.dart';
import '../../marketplace/services/service_service.dart';
import '../services/provider_service_service.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/age_requirement.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/verification_controller.dart';
import 'verification_status_screen.dart';
import 'verification_upload_panel.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

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
  /// At most the provider's age minus 16 (2 years at 18, 3 at 19...).
  late final int _maxExperience = AgeRequirement.maxExperienceYears(
      context.read<AuthController>().currentUser?.birthday);
  late int _yearsExperience = _maxExperience < 3 ? _maxExperience : 3;
  String _category = '';
  List<dynamic> _categories = [];

  int _step = 0;
  bool _savingProfile = false;
  /// The real verification state and upload (steps 2 and 3).
  final _verification = VerificationController();

  bool get _verified => _verification.verification?.isVerified ?? false;

  /// Documents are already with the reviewer (or approved): nothing to upload.
  bool get _alreadySubmitted =>
      _verification.verification != null && !_verification.verification!.canSubmit;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _verification.load();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _verification.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await ServiceService().getCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      if (categories.isNotEmpty) _category = categories.first.name;
    });
    _prefillFromProfile();
  }

  /// Seeds the form with what the provider already has, so continuing past
  /// this step never blanks a field they filled in earlier.
  Future<void> _prefillFromProfile() async {
    try {
      final profile = await ProviderServiceService().getMyProfile();
      if (!mounted) return;
      setState(() {
        if (profile.bio.isNotEmpty) _bioController.text = profile.bio;
        if (profile.yearsExperience > 0) {
          _yearsExperience = profile.yearsExperience.clamp(1, _maxExperience);
        }
        if (profile.categoryName.isNotEmpty) _category = profile.categoryName;
      });
    } catch (_) {
      // A provider without a profile yet simply starts from the defaults.
    }
  }

  /// Saves step 1 before advancing. Previously this screen collected the
  /// professional profile and then threw it away.
  Future<void> _saveProfile() async {
    if (_savingProfile) return;
    setState(() => _savingProfile = true);
    try {
      await ProviderServiceService().updateMyProfile({
        'bio': _bioController.text.trim(),
        'experience_years': _yearsExperience,
        if (_category.isNotEmpty) 'specialization': _category,
      });
      if (!mounted) return;
      setState(() {
        _savingProfile = false;
        _step++;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingProfile = false);
      AppSnackbar.error(
        context,
        apiErrorMessage(e, 'We could not save your profile. Please try again.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _verification,
      child: ListenableBuilder(
        listenable: _verification,
        builder: (context, _) => _buildScaffold(context),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get Verified'),
        leading: _step > 0
            ? IconButton(onPressed: () => setState(() => _step--), icon: const AppIcon(AppIcons.arrow_back_rounded))
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
          child: _step == 0
              ? PrimaryButton(
                  label: 'Save and continue',
                  icon: AppIcons.arrow_forward_rounded,
                  isLoading: _savingProfile,
                  onPressed: _saveProfile,
                )
              : _step == 1
                  ? (_alreadySubmitted
                      ? PrimaryButton(
                          label: 'Continue',
                          icon: AppIcons.arrow_forward_rounded,
                          onPressed: () => setState(() => _step = 2),
                        )
                      // Uploading happens in the panel above; this only leaves.
                      : OutlinedAppButton(
                          label: 'Do this later',
                          icon: AppIcons.home_rounded,
                          onPressed: _verification.isSubmitting ? null : () => context.go('/provider'),
                        ))
              : PrimaryButton(
                  label: _verified ? 'Go to dashboard' : 'Continue to dashboard',
                  icon: AppIcons.home_rounded,
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
                icon: const AppIcon(AppIcons.remove_circle_outline_rounded),
                color: context.accentInk,
              ),
              Expanded(
                child: Text(
                  '$_yearsExperience ${_yearsExperience == 1 ? 'year' : 'years'}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.monoLg.copyWith(color: context.accentInk),
                ),
              ),
              IconButton(
                onPressed: _yearsExperience < _maxExperience ? () => setState(() => _yearsExperience++) : null,
                icon: const AppIcon(AppIcons.add_circle_outline_rounded),
                color: context.accentInk,
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
            for (var i = 0; i < _categories.length; i++)
              ChoiceChip(
                label: Text(_categories[i].name),
                selected: _category == _categories[i].name,
                selectedColor: AppColors.secondary,
                labelStyle: AppTextStyles.label.copyWith(
                  color: _category == _categories[i].name ? AppColors.primary : null,
                  fontWeight: FontWeight.w600,
                ),
                showCheckmark: false,
                onSelected: (_) => setState(() => _category = _categories[i].name),
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
    final verification = _verification.verification;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upload your documents', style: AppTextStyles.titleLarge),
        const SizedBox(height: 4),
        Text(
          'A government-issued ID is required; add certificates or licenses for your trade if you have them. '
          'An administrator reviews them before you can list services.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSizes.lg),
        if (_verification.isLoading && verification == null)
          const Center(child: CircularProgressIndicator())
        else if (verification == null)
          Text(_verification.errorMessage ?? 'Unable to load your verification status.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error))
        else if (_alreadySubmitted)
          VerificationStatusHeader(verification: verification)
        else
          VerificationUploadPanel(onSubmitted: () => setState(() => _step = 2)),
      ],
    );
  }

  // ── Step 3: status seal ──
  Widget _stepStatus(BuildContext context) {
    final verification = _verification.verification;
    if (verification == null) return const Center(child: CircularProgressIndicator());
    return Column(
      children: [
        VerificationStatusHeader(verification: verification),
        if (!_verified) ...[
          const SizedBox(height: AppSizes.xl),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.secondarySoft,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Row(
              children: [
                const AppIcon(AppIcons.info_outline_rounded, color: AppColors.secondaryDeep, size: 18),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    'You can explore the app while your documents are reviewed; follow the status under Verification.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryDeep),
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

class _OnboardStepper extends StatelessWidget {
  final int current;
  final List<String> names;

  const _OnboardStepper({required this.current, required this.names});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad),
      // FittedBox keeps the whole stepper readable on narrow screens or with
      // large accessibility text — it scales down instead of overflowing.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < names.length; i++) ...[
              if (i > 0)
                Container(
                  width: 18,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: i <= current ? context.accentInk : AppColors.neutral100,
                    borderRadius: BorderRadius.circular(2),
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
                        ? const AppIcon(AppIcons.check_rounded, size: 16, color: AppColors.primary)
                        : Text(
                            '${i + 1}',
                            style: AppTextStyles.label.copyWith(
                              color: i <= current ? AppColors.primary : context.textMutedColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(names[i], style: AppTextStyles.caption.copyWith(
                  color: i <= current ? context.accentInk : context.textMutedColor,
                  fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                )),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }
}
