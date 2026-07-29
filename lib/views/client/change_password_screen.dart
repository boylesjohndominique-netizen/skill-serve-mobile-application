import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/inputs/app_text_field.dart';
import '../../services/profile_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _profileService = ProfileService();
  bool _saving = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await _profileService.changePassword(current: _current.text, next: _next.text);
    setState(() => _saving = false);
    if (mounted) {
      AppSnackbar.success(context, 'Password updated successfully.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keep your account secure', style: AppTextStyles.headlineLarge)
                    .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: 4),
                Text('Choose a strong password you don\'t use elsewhere.', style: AppTextStyles.bodyLarge)
                    .animate().fadeIn(delay: 80.ms, duration: 300.ms),
                const SizedBox(height: AppSizes.xl),
                AppTextField(label: 'Current password', controller: _current, obscureText: true, prefixIcon: Icons.lock_outline_rounded, validator: Validators.password)
                    .animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: AppSizes.lg),
                AppTextField(label: 'New password', controller: _next, obscureText: true, prefixIcon: Icons.lock_outline_rounded, validator: Validators.password)
                    .animate().fadeIn(delay: 230.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Confirm new password',
                  controller: _confirm,
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) => Validators.confirmPassword(v, _next.text),
                ).animate().fadeIn(delay: 310.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: AppSizes.xxl),
                PrimaryButton(label: 'Update password', isLoading: _saving, onPressed: _submit)
                    .animate().fadeIn(delay: 390.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
