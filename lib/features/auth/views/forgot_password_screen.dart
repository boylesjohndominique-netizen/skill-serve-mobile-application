import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../services/auth_service.dart';
import 'widgets/new_password_fields.dart';
import 'widgets/otp_code_field.dart';
import '../../../core/constants/app_icons.dart';

/// The steps of a password reset, in order.
enum _ResetStep { email, code, password, done }

/// Forgot password, in the app from start to finish:
///  1. the email — a 6-digit code is sent to it;
///  2. the code — traded for a single-use reset token;
///  3. the new password and its confirmation.
/// Setting it signs the account out on every device.
class ForgotPasswordScreen extends StatefulWidget {
  /// Prefills the address, e.g. from the Google password prompt.
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailForm = GlobalKey<FormState>();
  final _passwordForm = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _codeFocus = FocusNode();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _authService = AuthService();

  _ResetStep _step = _ResetStep.email;
  bool _loading = false;
  String? _resetToken;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _email.dispose();
    _code.dispose();
    _codeFocus.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// Mirrors the backend's 60-second resend window.
  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendCountdown--);
      if (_resendCountdown <= 0) timer.cancel();
    });
  }

  Future<void> _sendCode({bool resend = false}) async {
    if (!resend && !_emailForm.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authService.requestPasswordReset(_email.text.trim());
      if (!mounted) return;
      _code.clear();
      setState(() {
        _loading = false;
        _step = _ResetStep.code;
      });
      _startResendCountdown();
      // Only an address with an account gets here: the API answers 404 for
      // one without, and that message is shown below instead.
      AppSnackbar.success(context, 'A 6-digit code is on its way to your email.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppSnackbar.error(context, apiErrorMessage(e, 'We could not send the code. Please try again.'));
    }
  }

  Future<void> _verifyCode() async {
    // The field submits on the sixth digit; ignore a second trigger.
    if (_loading) return;
    final code = _code.text.trim();
    if (code.length != OtpCodeField.length) {
      AppSnackbar.error(context, 'Enter the complete 6-digit code.');
      return;
    }
    setState(() => _loading = true);
    try {
      final token = await _authService.verifyResetCode(email: _email.text.trim(), code: code);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _resetToken = token;
        _step = _ResetStep.password;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _code.clear();
      AppSnackbar.error(context, apiErrorMessage(e, 'That code did not work. Please try again.'));
    }
  }

  Future<void> _setPassword() async {
    if (!_passwordForm.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authService.resetPassword(
        email: _email.text.trim(),
        resetToken: _resetToken!,
        password: _password.text,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _step = _ResetStep.done;
      });
      AppSnackbar.success(context, 'Password changed. Log in with your new password.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      AppSnackbar.error(context, apiErrorMessage(e, 'We could not change your password. Please try again.'));
    }
  }

  (String, String) get _copy => switch (_step) {
        _ResetStep.email => (
            'Reset your password',
            'Enter the email of your account and we\'ll send you a 6-digit code.',
          ),
        _ResetStep.code => (
            'Enter the code',
            'We sent a 6-digit code to ${_email.text.trim()}. It expires in 10 minutes.',
          ),
        _ResetStep.password => (
            'Create a new password',
            'Choose the password you will use to log in — with your email, or with Google.',
          ),
        _ResetStep.done => (
            'Password changed',
            'You have been signed out on every device. Log in with your new password.',
          ),
      };

  @override
  Widget build(BuildContext context) {
    final (title, description) = _copy;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(title, key: ValueKey(_step), style: AppTextStyles.displayMedium),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(description, key: ValueKey('desc_$_step'), style: AppTextStyles.bodyLarge),
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.xxl),
              ...switch (_step) {
                _ResetStep.email => [
                    Form(
                      key: _emailForm,
                      child: AppTextField(
                        label: 'Email address',
                        hint: 'you@email.com',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: AppIcons.mail_outline_rounded,
                        validator: Validators.email,
                        // Locked while the request is in flight so the
                        // address cannot change under it.
                        enabled: !_loading,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xl),
                    PrimaryButton(label: 'Send code', isLoading: _loading, onPressed: _sendCode),
                  ],
                _ResetStep.code => [
                    OtpCodeField(
                      controller: _code,
                      focusNode: _codeFocus,
                      enabled: !_loading,
                      onCompleted: (_) => _verifyCode(),
                    ),
                    const SizedBox(height: AppSizes.xl),
                    PrimaryButton(label: 'Verify code', isLoading: _loading, onPressed: _verifyCode),
                    const SizedBox(height: AppSizes.md),
                    TextButton(
                      onPressed: (_loading || _resendCountdown > 0) ? null : () => _sendCode(resend: true),
                      child: Text(
                        _resendCountdown > 0 ? 'Resend code in ${_resendCountdown}s' : 'Didn\'t get the code? Resend it',
                      ),
                    ),
                    TextButton(
                      onPressed: _loading ? null : () => setState(() => _step = _ResetStep.email),
                      child: const Text('Use a different email'),
                    ),
                    Text(
                      'Check your spam folder if it doesn\'t arrive within a minute.',
                      style: AppTextStyles.caption.copyWith(color: muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                _ResetStep.password => [
                    Form(
                      key: _passwordForm,
                      child: NewPasswordFields(password: _password, confirmation: _confirm, enabled: !_loading),
                    ),
                    const SizedBox(height: AppSizes.xl),
                    PrimaryButton(label: 'Save new password', isLoading: _loading, onPressed: _setPassword),
                  ],
                _ResetStep.done => [
                    PrimaryButton(label: 'Back to log in', onPressed: () => context.go('/login')),
                  ],
              },
            ],
          ),
        ),
      ),
    );
  }
}
