import 'package:flutter/material.dart';

import 'widgets/account_restriction_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    final success = await auth.login(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (success) {
      context.go(auth.isProvider ? '/provider' : '/client');
      return;
    }
    AppSnackbar.error(context, auth.errorMessage ?? 'Login failed');
    // The credentials belong to a sign-up that never confirmed its code:
    // pick verification back up instead of leaving the user stuck.
    if (auth.requiresEmailVerification) {
      context.go(
          '/verify-email?email=${Uri.encodeComponent(auth.pendingEmail ?? _email.text.trim())}');
    }
  }

  Future<void> _signInWithGoogle(AuthController auth) async {
    final outcome = await auth.loginWithGoogle();
    if (!mounted) return;
    switch (outcome) {
      case GoogleAuthOutcome.signedIn:
        context.go(auth.isProvider ? '/provider' : '/client');
      case GoogleAuthOutcome.registrationRequired:
        // The Google account is new to SkillServe: finish signing up
        // rather than failing with "already registered".
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
    // While a sign-in is in flight every input is locked, so the values
    // cannot change under the request that is already using them.
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
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/welcome'),
                  icon: const AppIcon(AppIcons.arrow_back_rounded),
                  padding: EdgeInsets.zero,
                ).animate().fadeIn(duration: 250.ms),
                const SizedBox(height: AppSizes.md),
                Text('Welcome back', style: AppTextStyles.displayMedium)
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 350.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 6),
                Text('Log in to continue booking or managing your services.',
                        style: AppTextStyles.bodyLarge)
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 350.ms),
                const SizedBox(height: AppSizes.xxl),
                if (auth.restriction != null) ...[
                  AccountRestrictionCard(restriction: auth.restriction!),
                  const SizedBox(height: AppSizes.lg),
                ] else if (auth.sessionExpired) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.warningBg,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: const Text(
                        'You were signed out by the server. Please sign in again.'),
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],
                AppTextField(
                  label: 'Email address',
                  hint: 'you@email.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: AppIcons.mail_outline_rounded,
                  validator: Validators.email,
                  enabled: !isBusy,
                )
                    .animate()
                    .fadeIn(delay: 220.ms, duration: 350.ms)
                    .slideY(begin: 0.08, end: 0),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _password,
                  obscureText: true,
                  prefixIcon: AppIcons.lock_outline_rounded,
                  validator: Validators.password,
                  enabled: !isBusy,
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 350.ms)
                    .slideY(begin: 0.08, end: 0),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        isBusy ? null : () => context.push('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ).animate().fadeIn(delay: 380.ms, duration: 300.ms),
                const SizedBox(height: AppSizes.md),
                PrimaryButton(
                  label: 'Log in',
                  isLoading: isBusy,
                  onPressed: () => _submit(auth),
                )
                    .animate()
                    .fadeIn(delay: 440.ms, duration: 350.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: AppSizes.lg),
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: AppTextStyles.bodyMedium,
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: isBusy ? null : () => context.go('/register'),
                            child: Text('Sign up',
                                style: AppTextStyles.label.copyWith(
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
                const SizedBox(height: AppSizes.md),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                      child: Text('or', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ).animate().fadeIn(delay: 520.ms, duration: 300.ms),
                const SizedBox(height: AppSizes.md),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : () => _signInWithGoogle(auth),
                  icon: isBusy
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
                      : SizedBox(
                          width: 18,
                          height: 18,
                          child: CustomPaint(painter: _GoogleLogoPainter()),
                        ),
                  label: Text(
                    'Sign in with Google',
                    style: AppTextStyles.button.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textOnDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    side: BorderSide(color: AppColors.line.withValues(alpha: 0.8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                  ),
                ).animate().fadeIn(delay: 540.ms, duration: 300.ms),
                const SizedBox(height: AppSizes.sm),
                Center(
                  child: TextButton(
                    onPressed: isBusy ? null : () => context.go('/browse'),
                    child: Text('Continue as guest',
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.textMuted)),
                  ),
                ).animate().fadeIn(delay: 550.ms, duration: 300.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
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
