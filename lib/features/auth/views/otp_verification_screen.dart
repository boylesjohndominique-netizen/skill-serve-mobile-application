import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../models/user_model.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// Post-registration email verification: the backend emails a 6-digit code,
/// the user types it here. Confirming the code is what creates the account,
/// so this screen is the last step of sign-up, not a formality afterwards.
/// Resend is rate-limited (60s) by the backend.
class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const _codeLength = 6;

  /// The address being verified: the route's value, or the pending sign-up
  /// the controller is holding when the route carries none.
  String get _email {
    if (widget.email.isNotEmpty) return widget.email;
    return context.read<AuthController>().pendingEmail ?? '';
  }

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitting = false;
  bool _resending = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    // Cancel before disposing: a countdown left running would tick against
    // a dead widget.
    _resendTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Mirrors the backend's 60-second resend cooldown.
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

  Future<void> _verify() async {
    // The field auto-submits on the sixth digit, so guard against a second
    // request landing while the first is still in flight.
    if (_submitting) return;
    final code = _controller.text.trim();
    if (code.length != _codeLength) {
      AppSnackbar.error(context, 'Enter the complete 6-digit code.');
      return;
    }
    setState(() => _submitting = true);
    final auth = context.read<AuthController>();
    final email = _email;
    final ok = await auth.verifyOtp(email, code);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      // The account now exists and the response carried a real session, so
      // the router's requiresEmailVerification pin is released here.
      AppSnackbar.success(context, 'Email verified! Welcome to SkillServe.');
      context.go(auth.currentUser?.role == UserRole.provider
          ? '/provider-onboarding'
          : '/client');
    } else {
      AppSnackbar.error(context, auth.errorMessage ?? 'Verification failed.');
      _controller.clear();
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final auth = context.read<AuthController>();
    final email = _email;
    final ok = await auth.resendOtp(email);
    if (!mounted) return;
    setState(() => _resending = false);
    if (ok) {
      AppSnackbar.success(context, 'A new code is on its way to $email.');
      _controller.clear();
      _startResendCountdown();
    } else {
      AppSnackbar.error(context, auth.errorMessage ?? 'Could not resend the code.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  // Backing out cancels the sign-up: the parked registration
                  // is discarded server-side so the email is free to use
                  // again straight away. (Also covers the system back
                  // gesture — the router pins this screen while a
                  // verification is pending.)
                  onPressed: _submitting
                      ? null
                      : () async {
                    final auth = context.read<AuthController>();
                    await auth.cancelPendingVerification();
                    if (!context.mounted) return;
                    context.go('/login');
                  },
                  icon: const AppIcon(AppIcons.arrow_back_rounded),
                  tooltip: 'Cancel sign-up',
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: AppColors.secondarySoft,
                  shape: BoxShape.circle,
                ),
                child: const AppIcon(
                  AppIcons.mail_outline_rounded,
                  size: 36,
                  color: AppColors.secondaryDeep,
                ),
              ).animate().scale(duration: 450.ms, curve: Curves.easeOutBack).fadeIn(),
              const SizedBox(height: AppSizes.lg),
              Text('Check your email', style: AppTextStyles.displayMedium)
                  .animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: AppSizes.sm),
              Text(
                'We sent a 6-digit verification code to',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 180.ms, duration: 350.ms),
              const SizedBox(height: 4),
              Text(
                _email,
                style: AppTextStyles.titleMedium.copyWith(color: AppColors.secondary),
              ).animate().fadeIn(delay: 220.ms, duration: 350.ms),
              const SizedBox(height: AppSizes.xl),

              // Hidden real field + visual boxes (supports paste).
              GestureDetector(
                onTap: _submitting ? null : () => _focusNode.requestFocus(),
                child: Form(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Opacity(
                            opacity: 0,
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              keyboardType: TextInputType.number,
                              maxLength: _codeLength,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              autofocus: true,
                              // Locked while verifying so the code cannot
                              // change under the request using it.
                              enabled: !_submitting,
                              onChanged: (v) {
                                setState(() {});
                                if (v.length == _codeLength) _verify();
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              for (var i = 0; i < _codeLength; i++)
                                _OtpBox(
                                  character: _controller.text.length > i
                                      ? _controller.text[i]
                                      : '',
                                  isFocused:
                                      _controller.text.length == i && _focusNode.hasFocus,
                                  isDark: isDark,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms, duration: 350.ms),

              const SizedBox(height: AppSizes.xl),
              PrimaryButton(
                label: 'Verify email',
                isLoading: _submitting,
                onPressed: _verify,
              ).animate().fadeIn(delay: 380.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: AppSizes.lg),
              TextButton(
                onPressed: (_submitting || _resending || _resendCountdown > 0)
                    ? null
                    : _resend,
                child: Text(
                  _resendCountdown > 0
                      ? 'Resend code in ${_resendCountdown}s'
                      : 'Didn\'t get the code? Resend it',
                  style: AppTextStyles.label.copyWith(
                    color: _resendCountdown > 0
                        ? (isDark ? AppColors.textMutedDark : AppColors.textMuted)
                        : AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ).animate().fadeIn(delay: 440.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Check your spam folder if it doesn\'t arrive within a minute.',
                style: AppTextStyles.caption.copyWith(
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final String character;
  final bool isFocused;
  final bool isDark;

  const _OtpBox({
    required this.character,
    required this.isFocused,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isFocused ? AppColors.secondary : AppColors.neutral200;
    return AnimatedContainer(
      duration: AppAnimations.fast,
      curve: AppAnimations.defaultCurve,
      width: 44,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: borderColor, width: isFocused ? 1.8 : 1.2),
        boxShadow: isFocused
            ? [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
            : [],
      ),
      child: Text(
        character,
        style: AppTextStyles.monoLg.copyWith(
          color: isDark ? AppColors.textOnDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}
