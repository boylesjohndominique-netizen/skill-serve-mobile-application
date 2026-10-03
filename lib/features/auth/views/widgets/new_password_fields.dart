import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/inputs/app_text_field.dart';

/// A new password and its confirmation — the last step of sign-up and of a
/// password reset. Validates inside the surrounding [Form].
class NewPasswordFields extends StatelessWidget {
  final TextEditingController password;
  final TextEditingController confirmation;
  final bool enabled;

  const NewPasswordFields({
    super.key,
    required this.password,
    required this.confirmation,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          label: 'Password',
          hint: 'At least 8 characters',
          controller: password,
          obscureText: true,
          prefixIcon: AppIcons.lock_outline_rounded,
          validator: Validators.password,
          enabled: enabled,
        ),
        const SizedBox(height: AppSizes.lg),
        AppTextField(
          label: 'Confirm password',
          hint: 'Re-enter your password',
          controller: confirmation,
          obscureText: true,
          prefixIcon: AppIcons.lock_outline_rounded,
          validator: (value) => Validators.confirmPassword(value, password.text),
          enabled: enabled,
        ),
      ],
    );
  }
}
