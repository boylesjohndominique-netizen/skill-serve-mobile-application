import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/inputs/app_text_field.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _sent = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await _authService.requestPasswordReset(_email.text.trim());
    setState(() {
      _loading = false;
      _sent = true;
    });
    if (mounted) AppSnackbar.success(context, 'Reset link sent — check your inbox.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sent ? 'Check your email' : 'Reset your password',
                  style: AppTextStyles.displayMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  _sent
                      ? 'We\'ve sent a password reset link to ${_email.text}. Follow the instructions to set a new password.'
                      : 'Enter the email associated with your account and we\'ll send a link to reset your password.',
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: AppSizes.xxl),
                if (!_sent) ...[
                  AppTextField(
                    label: 'Email address',
                    hint: 'you@email.com',
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline_rounded,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: AppSizes.xl),
                  PrimaryButton(label: 'Send reset link', isLoading: _loading, onPressed: _submit),
                ] else
                  PrimaryButton(label: 'Back to log in', onPressed: () => context.go('/login')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
