import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/inputs/app_text_field.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  Future<void> _submit(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    final success = await auth.login(_email.text.trim(), _password.text);
    if (!mounted) return;
    if (success) {
      context.go(auth.isProvider ? '/provider' : '/client');
    } else {
      AppSnackbar.error(context, auth.errorMessage ?? 'Login failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
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
                  onPressed: () => context.canPop() ? context.pop() : context.go('/welcome'),
                  icon: const AppIcon(AppIcons.arrow_back_rounded),
                  padding: EdgeInsets.zero,
                ).animate().fadeIn(duration: 250.ms),
                const SizedBox(height: AppSizes.md),
                Text('Welcome back', style: AppTextStyles.displayMedium)
                    .animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 6),
                Text('Log in to continue booking or managing your services.', style: AppTextStyles.bodyLarge)
                    .animate().fadeIn(delay: 150.ms, duration: 350.ms),
                const SizedBox(height: AppSizes.xxl),
                AppTextField(
                  label: 'Email address',
                  hint: 'you@email.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: AppIcons.mail_outline_rounded,
                  validator: Validators.email,
                ).animate().fadeIn(delay: 220.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Password',
                  hint: '••••••••',
                  controller: _password,
                  obscureText: true,
                  prefixIcon: AppIcons.lock_outline_rounded,
                  validator: Validators.password,
                ).animate().fadeIn(delay: 300.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ).animate().fadeIn(delay: 380.ms, duration: 300.ms),
                const SizedBox(height: AppSizes.md),
                PrimaryButton(
                  label: 'Log in',
                  isLoading: auth.status == AuthStatus.authenticating,
                  onPressed: () => _submit(auth),
                ).animate().fadeIn(delay: 440.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),
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
                            onTap: () => context.go('/register'),
                            child: Text('Sign up', style: AppTextStyles.label.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
                const SizedBox(height: AppSizes.sm),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/browse'),
                    child: Text('Continue as guest', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
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
