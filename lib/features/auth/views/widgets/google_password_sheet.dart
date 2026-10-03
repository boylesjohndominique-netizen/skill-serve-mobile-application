import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/buttons/primary_button.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';

/// Asks for the account password after "Continue with Google" picked an
/// account that exists: Google says who the user is, the password signs in.
///
/// Returns true once signed in. Closing the sheet forgets the Google
/// sign-in; "Forgot password?" is the way in for an account that never had
/// a password of its own (made by Google sign-up before passwords were
/// required).
Future<bool> showGooglePasswordSheet(BuildContext context) async {
  final signedIn = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _GooglePasswordSheet(),
  );
  if (signedIn != true && context.mounted) {
    context.read<AuthController>().cancelGooglePassword();
  }
  return signedIn == true;
}

class _GooglePasswordSheet extends StatefulWidget {
  const _GooglePasswordSheet();

  @override
  State<_GooglePasswordSheet> createState() => _GooglePasswordSheetState();
}

class _GooglePasswordSheetState extends State<_GooglePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController auth) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await auth.signInWithGooglePassword(_password.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = auth.errorMessage ?? 'Google sign-in failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isBusy = auth.status == AuthStatus.authenticating;
    final email = auth.googlePasswordEmail ?? '';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.xl,
        AppSizes.lg,
        AppSizes.xl,
        AppSizes.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Enter your password', style: AppTextStyles.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Google confirmed it is you. Enter the password of your SkillServe account to finish logging in.',
              style: AppTextStyles.bodyMedium,
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: AppSizes.sm),
              Text(email, style: AppTextStyles.label),
            ],
            const SizedBox(height: AppSizes.lg),
            AppTextField(
              label: 'Password',
              hint: '••••••••',
              controller: _password,
              obscureText: true,
              prefixIcon: AppIcons.lock_outline_rounded,
              validator: (v) => v == null || v.isEmpty ? 'Password is required' : null,
              enabled: !isBusy,
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSizes.sm),
              Text(_error!, style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.error)),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isBusy
                    ? null
                    : () {
                        Navigator.of(context).pop(false);
                        context.push('/forgot-password?email=${Uri.encodeComponent(email)}');
                      },
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            PrimaryButton(label: 'Log in', isLoading: isBusy, onPressed: () => _submit(auth)),
          ],
        ),
      ),
    );
  }
}
