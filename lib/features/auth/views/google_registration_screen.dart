import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../../identity/views/sign_up_identity_fields.dart';
import '../../identity/views/national_id_scan_flow.dart';
import '../../identity/models/scanned_national_id.dart';
import '../../identity/models/identity_verification_model.dart';
import '../../identity/controllers/identity_controller.dart';
import '../../identity/services/sign_up_scan_store.dart';
import '../models/user_model.dart';
import 'widgets/auth_role_toggle.dart';
import 'widgets/provider_details_fields.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/theme/app_palette.dart';

/// Shown when "Continue with Google" picks an account that has no
/// SkillServe account yet. Google gave us a verified email and a name; the
/// user confirms those and chooses whether they are here to book services
/// or to offer them.
///
/// Submitting it starts the same steps as an email sign-up: a 6-digit code
/// to the Google address, then a password. Nothing exists server-side until
/// those are done, so leaving cancels the sign-up cleanly and the same
/// Google account can start over — as either role.
class GoogleRegistrationScreen extends StatefulWidget {
  const GoogleRegistrationScreen({super.key});

  @override
  State<GoogleRegistrationScreen> createState() =>
      _GoogleRegistrationScreenState();
}

class _GoogleRegistrationScreenState extends State<GoogleRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityForm = SignUpIdentityForm();
  bool _scanned = false;
  bool _preparing = false;
  final _businessName = TextEditingController();
  final _specialization = TextEditingController();
  final _experienceYears = TextEditingController();
  final _bio = TextEditingController();
  UserRole _role = UserRole.client;

  @override
  void initState() {
    super.initState();
    // Scanned already on the register screen before choosing Google.
    final identity = context.read<IdentityController>();
    final scanned = identity.scanned;
    if (scanned != null && identity.hasFront && identity.hasBack) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onScanned(scanned));
    }
  }

  Future<void> _onScanned(ScannedNationalId id) async {
    setState(() => _preparing = true);
    await _identityForm.fillFromScan(id);
    if (!mounted) return;
    setState(() {
      _preparing = false;
      _scanned = true;
    });
  }

  void _rescan() {
    SignUpScanStore.clear();
    context.read<IdentityController>()
      ..remove(PendingIdentityDocument.frontType)
      ..remove(PendingIdentityDocument.backType)
      ..scanned = null;
    setState(() => _scanned = false);
  }

  @override
  void dispose() {
    _identityForm.dispose();
    _businessName.dispose();
    _specialization.dispose();
    _experienceYears.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _cancel(AuthController auth) async {
    auth.cancelGoogleRegistration();
    unawaited(SignUpScanStore.clear());
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> _submit(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    final isProvider = _role == UserRole.provider;
    context.read<IdentityController>().setScanned(_identityForm.confirmed);
    // Read before the call: starting the sign-up clears the draft.
    final googleEmail = auth.googleDraft?.email ?? '';
    // The name on the National ID, not Google's display name: the ID is what
    // gets reviewed.
    final started = await auth.completeGoogleRegistration(
      firstName: _identityForm.givenNames.text.trim(),
      lastName: _identityForm.lastName.text.trim(),
      signUpDetails: _identityForm.signUpDetails,
      role: _role,
      businessName: isProvider ? _businessName.text.trim() : null,
      specialization: isProvider ? _specialization.text.trim() : '',
      experienceYears: isProvider
          ? ProviderDetailsFields.parseExperience(_experienceYears.text)
          : 0,
      bio: isProvider ? _bio.text.trim() : null,
    );
    if (!mounted) return;
    if (started) {
      // Same steps as an email sign-up: the code, then the password. The
      // National ID scanned before the form is sent once the account exists.
      AppSnackbar.success(context, auth.errorMessage ?? 'We sent a 6-digit code to $googleEmail.');
      context.go('/verify-email?email=${Uri.encodeComponent(auth.pendingEmail ?? googleEmail)}');
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

    final isProvider = _role == UserRole.provider;
    final isBusy = auth.status == AuthStatus.authenticating;

    if (!_scanned) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _cancel(auth);
        },
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => _cancel(auth),
                      icon: const AppIcon(AppIcons.arrow_back_rounded),
                      tooltip: 'Cancel sign-up',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text('Finish signing up', style: AppTextStyles.displayMedium),
                  const SizedBox(height: 6),
                  Text('Scan your National ID — your details are filled in from it.', style: AppTextStyles.bodyLarge),
                  const SizedBox(height: AppSizes.lg),
                  _GoogleAccountChip(email: draft.email),
                  const SizedBox(height: AppSizes.xl),
                  if (_preparing)
                    const Padding(
                      padding: EdgeInsets.all(AppSizes.xl),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    NationalIdScanFlow(onComplete: _onScanned),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                    'We got your email from Google. Check the details from your ID and tell us how you will use SkillServe.',
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
                  SignUpIdentityFields(form: _identityForm, onRescan: _rescan, enabled: !isBusy),
                  if (isProvider) ...[
                    const SizedBox(height: AppSizes.xl),
                    ProviderDetailsFields(
                      businessName: _businessName,
                      specialization: _specialization,
                      experienceYears: _experienceYears,
                      bio: _bio,
                      birthdate: () => _identityForm.birthdate,
                      enabled: !isBusy,
                    ).animate().fadeIn(duration: 250.ms),
                  ],
                  const SizedBox(height: AppSizes.xl),
                  PrimaryButton(
                    label: 'Continue',
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
                          .copyWith(color: context.textMutedColor),
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
