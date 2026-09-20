import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'widgets/auth_role_toggle.dart';
import 'widgets/provider_details_fields.dart';
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _businessName = TextEditingController();
  final _specialization = TextEditingController();
  final _experienceYears = TextEditingController();
  final _bio = TextEditingController();
  UserRole _role = UserRole.client;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _businessName.dispose();
    _specialization.dispose();
    _experienceYears.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    final isProvider = _role == UserRole.provider;
    final success = await auth.register(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
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
      // first, and that is what creates it. A code that was already sent
      // moments ago still counts, and says so.
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
                      : () => context.canPop() ? context.pop() : context.go('/welcome'),
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

                Row(
                  children: [
                    Expanded(
                      child: AppTextField(label: 'First name', hint: 'Juan', controller: _firstName, validator: Validators.required, enabled: !isBusy),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: AppTextField(label: 'Last name', hint: 'Dela Cruz', controller: _lastName, validator: Validators.required, enabled: !isBusy),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
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
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Password',
                  hint: 'At least 8 characters',
                  controller: _password,
                  obscureText: true,
                  prefixIcon: AppIcons.lock_outline_rounded,
                  validator: Validators.password,
                  enabled: !isBusy,
                ).animate().fadeIn(delay: 440.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Confirm password',
                  hint: 'Re-enter your password',
                  controller: _confirm,
                  obscureText: true,
                  prefixIcon: AppIcons.lock_outline_rounded,
                  validator: (v) => Validators.confirmPassword(v, _password.text),
                  enabled: !isBusy,
                ).animate().fadeIn(delay: 510.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
                if (_role == UserRole.provider) ...[
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
                  label: 'Create account',
                  isLoading: isBusy,
                  onPressed: () => _submit(auth),
                ).animate().fadeIn(delay: 580.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: AppSizes.md),
                _GoogleButton(
                  isLoading: isBusy,
                  onPressed: () => _signInWithGoogle(auth),
                ).animate().fadeIn(delay: 620.ms, duration: 350.ms),
                const SizedBox(height: AppSizes.md),
                Center(
                  child: Text(
                    'By continuing, you agree to our Terms & Privacy Policy.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
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
                            child: Text('Log in', style: AppTextStyles.label.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
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
