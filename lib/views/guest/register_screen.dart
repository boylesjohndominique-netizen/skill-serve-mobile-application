import 'package:flutter/material.dart';
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
import '../../models/user_model.dart';

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
      context.go(_role == UserRole.provider ? '/provider' : '/client');
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
                  icon: const Icon(Icons.arrow_back_rounded),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSizes.md),
                Text('Create your account', style: AppTextStyles.displayMedium),
                const SizedBox(height: 6),
                Text('Join SkillLink as a client looking for services, or a provider offering them.', style: AppTextStyles.bodyLarge),
                const SizedBox(height: AppSizes.xl),

                _RoleToggle(role: _role, onChanged: (r) => setState(() => _role = r)),
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
                ),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Email address',
                  hint: 'you@email.com',
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  validator: Validators.email,
                ),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Password',
                  hint: 'At least 8 characters',
                  controller: _password,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: Validators.password,
                ),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Confirm password',
                  hint: 'Re-enter your password',
                  controller: _confirm,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) => Validators.confirmPassword(v, _password.text),
                ),
                const SizedBox(height: AppSizes.xl),
                PrimaryButton(
                  label: 'Create account',
                  isLoading: auth.status == AuthStatus.authenticating,
                  onPressed: () => _submit(auth),
                ),
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
                ),
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
      child: Row(
        children: [
          Expanded(child: _tab('I need a service', UserRole.client, Icons.person_search_rounded)),
          Expanded(child: _tab('I offer a service', UserRole.provider, Icons.handyman_rounded)),
        ],
      ),
    );
  }

  Widget _tab(String label, UserRole value, IconData icon) {
    final selected = role == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: selected ? Colors.white : AppColors.textMuted),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: selected ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
