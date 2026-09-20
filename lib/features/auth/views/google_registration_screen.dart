import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import 'widgets/auth_role_toggle.dart';
import 'widgets/provider_details_fields.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/misc/app_icon.dart';

/// Shown when "Continue with Google" picks an account that has no
/// SkillServe account yet. Google gave us a verified email and a name; the
/// user confirms those and chooses whether they are here to book services
/// or to offer them.
///
/// Nothing exists server-side until this form is submitted, so leaving the
/// screen cancels the sign-up cleanly and the same Google account can start
/// over — as either role.
class GoogleRegistrationScreen extends StatefulWidget {
  const GoogleRegistrationScreen({super.key});

  @override
  State<GoogleRegistrationScreen> createState() =>
      _GoogleRegistrationScreenState();
}

class _GoogleRegistrationScreenState extends State<GoogleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _businessName = TextEditingController();
  final _specialization = TextEditingController();
  final _experienceYears = TextEditingController();
  final _bio = TextEditingController();
  UserRole _role = UserRole.client;
  bool _prefilled = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _businessName.dispose();
    _specialization.dispose();
    _experienceYears.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _prefillOnce(AuthController auth) {
    if (_prefilled) return;
    final draft = auth.googleDraft;
    if (draft == null) return;
    _firstName.text = draft.firstName;
    _lastName.text = draft.lastName;
    _prefilled = true;
  }

  Future<void> _cancel(AuthController auth) async {
    auth.cancelGoogleRegistration();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _submit(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    final isProvider = _role == UserRole.provider;
    final created = await auth.completeGoogleRegistration(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      role: _role,
      businessName: isProvider ? _businessName.text.trim() : null,
      specialization: isProvider ? _specialization.text.trim() : '',
      experienceYears: isProvider
          ? ProviderDetailsFields.parseExperience(_experienceYears.text)
          : 0,
      bio: isProvider ? _bio.text.trim() : null,
    );
    if (!mounted) return;
    if (created) {
      AppSnackbar.success(context, 'Welcome to SkillServe!');
      context.go(auth.isProvider ? '/provider-onboarding' : '/client');
    } else {
      AppSnackbar.error(context, auth.errorMessage ?? 'Could not finish signing up.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final draft = auth.googleDraft;

    // The draft is gone (cancelled, or the app restarted): there is nothing
    // to finish, so send the user back to sign in.
    if (draft == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppIcon(AppIcons.lock_outline_rounded, size: 40),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Your Google sign-in expired. Please start again.',
                  style: AppTextStyles.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.xl),
                PrimaryButton(
                  label: 'Back to log in',
                  onPressed: () => context.go('/login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    _prefillOnce(auth);
    final isProvider = _role == UserRole.provider;
    final isBusy = auth.status == AuthStatus.authenticating;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel(auth);
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: isBusy ? null : () => _cancel(auth),
                    icon: const AppIcon(AppIcons.arrow_back_rounded),
                    tooltip: 'Cancel sign-up',
                    padding: EdgeInsets.zero,
                  ).animate().fadeIn(duration: 250.ms),
                  const SizedBox(height: AppSizes.md),
                  Text('Finish signing up', style: AppTextStyles.displayMedium)
                      .animate()
                      .fadeIn(delay: 80.ms, duration: 350.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 6),
                  Text(
                    'We got your email from Google. Tell us your name and how you will use SkillServe.',
                    style: AppTextStyles.bodyLarge,
                  ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
                  const SizedBox(height: AppSizes.lg),
                  _GoogleAccountChip(email: draft.email)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 350.ms),
                  const SizedBox(height: AppSizes.xl),
                  AuthRoleToggle(
                    role: _role,
                    enabled: !isBusy,
                    onChanged: (r) => setState(() => _role = r),
                  )
                      .animate()
                      .fadeIn(delay: 240.ms, duration: 350.ms)
                      .slideY(begin: 0.08, end: 0),
                  const SizedBox(height: AppSizes.xl),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'First name',
                          hint: 'Juan',
                          controller: _firstName,
                          validator: (v) =>
                              Validators.required(v, field: 'First name'),
                          enabled: !isBusy,
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: AppTextField(
                          label: 'Last name',
                          hint: 'Dela Cruz',
                          controller: _lastName,
                          validator: (v) =>
                              Validators.required(v, field: 'Last name'),
                          enabled: !isBusy,
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 350.ms)
                      .slideY(begin: 0.08, end: 0),
                  if (isProvider) ...[
                    const SizedBox(height: AppSizes.xl),
                    ProviderDetailsFields(
                      businessName: _businessName,
                      specialization: _specialization,
                      experienceYears: _experienceYears,
                      bio: _bio,
                      enabled: !isBusy,
                    ).animate().fadeIn(duration: 250.ms),
                  ],
                  const SizedBox(height: AppSizes.xl),
                  PrimaryButton(
                    label: 'Create my account',
                    isLoading: isBusy,
                    onPressed: () => _submit(auth),
                  )
                      .animate()
                      .fadeIn(delay: 360.ms, duration: 350.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: AppSizes.md),
                  Center(
                    child: Text(
                      'By continuing, you agree to our Terms & Privacy Policy.',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only reminder of which Google account is being signed up. The email
/// is fixed by the verified Google token and cannot be edited here.
class _GoogleAccountChip extends StatelessWidget {
  final String email;

  const _GoogleAccountChip({required this.email});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'Signing up with the Google account $email',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            const AppIcon(AppIcons.mail_outline_rounded, size: 20),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
