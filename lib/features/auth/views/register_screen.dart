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
import 'widgets/auth_role_toggle.dart';
import 'widgets/provider_details_fields.dart';
import 'widgets/google_password_sheet.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../auth/models/user_model.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identityForm = SignUpIdentityForm();

  /// Sign-up starts with the National ID: the form appears once both sides
  /// are photographed and read.
  bool _scanned = false;
  bool _preparing = false;
  final _email = TextEditingController();
  final _businessName = TextEditingController();
  final _specialization = TextEditingController();
  final _experienceYears = TextEditingController();
  final _bio = TextEditingController();
  UserRole _role = UserRole.client;

  @override
  void initState() {
    super.initState();
    // Back from Google sign-up, or the screen rebuilt: reuse the scan.
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

  /// Leaving sign-up: a restart must not bring it back.
  void _leave() {
    SignUpScanStore.clear();
    context.canPop() ? context.pop() : context.go('/welcome');
  }

  @override
  void dispose() {
    _identityForm.dispose();
    _email.dispose();
    _businessName.dispose();
    _specialization.dispose();
    _experienceYears.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    final isProvider = _role == UserRole.provider;
    // What the user confirmed is what goes for review after the email code.
    context.read<IdentityController>().setScanned(_identityForm.confirmed);
    final success = await auth.register(
      firstName: _identityForm.givenNames.text.trim(),
      lastName: _identityForm.lastName.text.trim(),
      signUpDetails: _identityForm.signUpDetails,
      email: _email.text.trim(),
      role: _role,
      businessName: isProvider ? _businessName.text.trim() : null,
      specialization: isProvider ? _specialization.text.trim() : '',
      experienceYears: isProvider
          ? ProviderDetailsFields.parseExperience(_experienceYears.text)
          : 0,
      bio: isProvider ? _bio.text.trim() : null,
    );
    if (!mounted) return;
    if (success) {
      // No account exists yet: both roles confirm the emailed 6-digit code
      // first, then choose a password, and that is what creates it. A code
      // that was already sent moments ago still counts, and says so.
      if (auth.errorMessage != null) {
        AppSnackbar.success(context, auth.errorMessage!);
      }
      context.go('/verify-email?email=${Uri.encodeComponent(_email.text.trim())}');
    } else {
      AppSnackbar.error(context, auth.errorMessage ?? 'Registration failed');
    }
  }

  Future<void> _signInWithGoogle(AuthController auth) async {
    final outcome = await auth.loginWithGoogle();
    if (!mounted) return;
    switch (outcome) {
      case GoogleAuthOutcome.signedIn:
        context.go(auth.isProvider ? '/provider' : '/client');
      case GoogleAuthOutcome.registrationRequired:
        // Brand-new Google account: collect the name and role before
        // anything is written.
        context.go('/google-register');
      case GoogleAuthOutcome.passwordRequired:
        // This Google account already has a SkillServe account: log in to it
        // with its password instead of signing up again.
        if (await showGooglePasswordSheet(context) && mounted) {
          context.go(auth.isProvider ? '/provider' : '/client');
        }
      case GoogleAuthOutcome.cancelled:
        break;
      case GoogleAuthOutcome.failed:
        AppSnackbar.error(
            context, auth.errorMessage ?? 'Google sign-in failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    // Everything locks while the sign-up request is in flight.
    final isBusy = auth.status == AuthStatus.authenticating;
    if (!_scanned) {
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: _leave,
                    icon: const AppIcon(AppIcons.arrow_back_rounded),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Text('Create your account', style: AppTextStyles.displayMedium),
                const SizedBox(height: 6),
                Text('Start with your National ID — your details are filled in from it.', style: AppTextStyles.bodyLarge),
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
      );
    }
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: isBusy
                      ? null
                      : _leave,
                  icon: const AppIcon(AppIcons.arrow_back_rounded),
                  padding: EdgeInsets.zero,
                ).animate().fadeIn(duration: 250.ms),
                const SizedBox(height: AppSizes.md),
                Text('Create your account', style: AppTextStyles.displayMedium)
                    .animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 6),
                Text('Join SkillServe as a client looking for services, or a provider offering them.', style: AppTextStyles.bodyLarge)
                    .animate().fadeIn(delay: 150.ms, duration: 350.ms),
                const SizedBox(height: AppSizes.xl),

                AuthRoleToggle(
                  role: _role,
                  enabled: !isBusy,
                  onChanged: (r) => setState(() => _role = r),
                )
                    .animate().fadeIn(delay: 220.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: AppSizes.xl),

                SignUpIdentityFields(form: _identityForm, onRescan: _rescan, enabled: !isBusy),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Email address',
                  hint: 'you@email.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: AppIcons.mail_outline_rounded,
                  validator: Validators.email,
                  enabled: !isBusy,
                ).animate().fadeIn(delay: 370.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: AppSizes.sm),
                // The password comes after the emailed code.
                Text(
                  'We will email you a 6-digit code. After you enter it, you will create your password.',
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark ? AppColors.textMutedDark : AppColors.textMuted,
                  ),
                ),
                if (_role == UserRole.provider) ...[
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
                ).animate().fadeIn(delay: 580.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: AppSizes.md),
                _GoogleButton(
                  isLoading: isBusy,
                  onPressed: () => _signInWithGoogle(auth),
                ).animate().fadeIn(delay: 620.ms, duration: 350.ms),
                const SizedBox(height: AppSizes.md),
                // The policies administrators publish (M 14.4).
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('By continuing, you agree to our ',
                        style: AppTextStyles.caption.copyWith(color: context.textMutedColor)),
                    for (final (label, route) in const [
                      ('Terms', '/terms'),
                      ('Privacy Policy', '/privacy'),
                      ('Community Guidelines', '/community-guidelines'),
                    ])
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => context.push(route),
                        child: Text(label, style: AppTextStyles.caption.copyWith(color: context.accentInk)),
                      ),
                  ],
                ).animate().fadeIn(delay: 640.ms, duration: 300.ms),
                const SizedBox(height: AppSizes.md),
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: AppTextStyles.bodyMedium,
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: isBusy ? null : () => context.go('/login'),
                            child: Text('Log in', style: AppTextStyles.label.copyWith(color: context.accentInk, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 640.ms, duration: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? AppColors.textOnDark : AppColors.textPrimary,
        side: BorderSide(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.8)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          else
            const _GoogleLogo(),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Continue with Google',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.button.copyWith(color: isDark ? AppColors.textOnDark : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // Simplified four-color Google "G".
    final blue = Paint()..color = const Color(0xFF4285F4);
    final green = Paint()..color = const Color(0xFF34A853);
    final yellow = Paint()..color = const Color(0xFFFBBC05);
    final red = Paint()..color = const Color(0xFFEA4335);

    canvas.drawArc(Rect.fromLTWH(0, 0, s, s), 3.14159, 1.5708, true, red);
    canvas.drawArc(Rect.fromLTWH(0, 0, s, s), 4.71239, 1.5708, true, yellow);
    canvas.drawArc(Rect.fromLTWH(0, 0, s, s), 0, 1.5708, true, green);
    canvas.drawRect(Rect.fromLTWH(s * 0.45, s * 0.42, s * 0.55, s * 0.16), blue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
