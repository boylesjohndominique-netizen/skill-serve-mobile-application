import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../../identity/controllers/identity_controller.dart';
import '../../identity/views/sign_up_identity_fields.dart';
import 'widgets/new_password_fields.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/misc/app_icon.dart';

/// The last step of sign-up, after the emailed code: the password, for email
/// and Google sign-ups alike. Submitting it creates the account and signs in;
/// the router keeps the user here until then.
class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  /// Stays true through the National ID upload that follows, so the screen
  /// cannot be used twice.
  bool _submitting = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final auth = context.read<AuthController>();
    final identity = context.read<IdentityController>();
    final created = await auth.completeRegistration(_password.text);
    if (!mounted) return;
    if (!created) {
      setState(() => _submitting = false);
      AppSnackbar.error(context, auth.errorMessage ?? 'We could not create your account.');
      return;
    }
    AppSnackbar.success(context, 'Account created! Welcome to SkillServe.');
    // The National ID scanned at the start of sign-up goes for review now
    // that the account exists. A provider carries on to their business
    // onboarding either way.
    final next = await submitScannedIdAndRoute(identity, isProvider: auth.isProvider);
    if (!mounted) return;
    context.go(next);
  }

  Future<void> _cancel() async {
    final auth = context.read<AuthController>();
    await auth.cancelPendingVerification();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final email = context.select<AuthController, String?>((a) => a.pendingEmail) ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      // Backing out cancels the sign-up, as on the code screen.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_submitting) _cancel();
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: _submitting ? null : _cancel,
                      icon: const AppIcon(AppIcons.arrow_back_rounded),
                      tooltip: 'Cancel sign-up',
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text('Create your password', style: AppTextStyles.displayMedium)
                      .animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 6),
                  Text(
                    'Your email is verified. Choose the password you will use to log in — with your email, or with Google.',
                    style: AppTextStyles.bodyLarge,
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.md),
                    Row(
                      children: [
                        AppIcon(AppIcons.mail_outline_rounded,
                            size: 18, color: isDark ? AppColors.textMutedDark : AppColors.textMuted),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(child: Text(email, style: AppTextStyles.titleMedium)),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSizes.xl),
                  NewPasswordFields(
                    password: _password,
                    confirmation: _confirm,
                    enabled: !_submitting,
                  ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
                  const SizedBox(height: AppSizes.xl),
                  PrimaryButton(
                    label: 'Create account',
                    isLoading: _submitting,
                    onPressed: _submit,
                  ).animate().fadeIn(delay: 300.ms, duration: 350.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
