import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/constants/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/inputs/app_text_field.dart';
import '../../models/user_model.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

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
  UserRole _role = UserRole.client;

  Future<void> _submit(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    final success = await auth.register(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      role: _role,
    );
    if (!mounted) return;
    if (success) {
      // Providers land on the verification gate first (spec P1/P2).
      context.go(_role == UserRole.provider ? '/provider-onboarding' : '/client');
    } else {
      AppSnackbar.error(context, auth.errorMessage ?? 'Registration failed');
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
                Text('Create your account', style: AppTextStyles.displayMedium)
                    .animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 6),
                Text('Join SkillServe as a client looking for services, or a provider offering them.', style: AppTextStyles.bodyLarge)
                    .animate().fadeIn(delay: 150.ms, duration: 350.ms),
                const SizedBox(height: AppSizes.xl),

                _RoleToggle(role: _role, onChanged: (r) => setState(() => _role = r))
                    .animate().fadeIn(delay: 220.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: AppSizes.xl),

                Row(
                  children: [
                    Expanded(
                      child: AppTextField(label: 'First name', hint: 'Juan', controller: _firstName, validator: Validators.required),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: AppTextField(label: 'Last name', hint: 'Dela Cruz', controller: _lastName, validator: Validators.required),
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
                ).animate().fadeIn(delay: 370.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Password',
                  hint: 'At least 8 characters',
                  controller: _password,
                  obscureText: true,
                  prefixIcon: AppIcons.lock_outline_rounded,
                  validator: Validators.password,
                ).animate().fadeIn(delay: 440.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Confirm password',
                  hint: 'Re-enter your password',
                  controller: _confirm,
                  obscureText: true,
                  prefixIcon: AppIcons.lock_outline_rounded,
                  validator: (v) => Validators.confirmPassword(v, _password.text),
                ).animate().fadeIn(delay: 510.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: AppSizes.xl),
                PrimaryButton(
                  label: 'Create account',
                  isLoading: auth.status == AuthStatus.authenticating,
                  onPressed: () => _submit(auth),
                ).animate().fadeIn(delay: 580.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: AppSizes.lg),
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: AppTextStyles.bodyMedium,
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () => context.go('/login'),
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

class _RoleToggle extends StatelessWidget {
  final UserRole role;
  final void Function(UserRole) onChanged;

  const _RoleToggle({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      child: Row(
        children: [
          Expanded(child: _tab('I need a service', UserRole.client, AppIcons.person_search_rounded)),
          Expanded(child: _tab('I offer a service', UserRole.provider, AppIcons.handyman_rounded)),
        ],
      ),
    );
  }

  Widget _tab(String label, UserRole value, AppIconData icon) {
    final selected = role == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: AppAnimations.md,
        curve: AppAnimations.defaultCurve,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Column(
          children: [
            AnimatedScale(
              scale: selected ? 1.1 : 1.0,
              duration: AppAnimations.md,
              curve: AppAnimations.springCurve,
              child: AppIcon(icon, size: 20, color: selected ? AppColors.primary : AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: selected ? AppColors.primary : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
