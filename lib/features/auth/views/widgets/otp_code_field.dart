import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_animations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/theme/app_palette.dart';

/// Six boxes for an emailed one-time code: a hidden text field (so typing
/// and pasting both work) drawn as one box per digit. Used for the sign-up
/// code and the password reset code.
class OtpCodeField extends StatelessWidget {
  static const length = 6;

  final TextEditingController controller;
  final FocusNode focusNode;

  /// Locked while a code is being checked, so it cannot change under the
  /// request using it.
  final bool enabled;

  /// Called with the full code as soon as the sixth digit is typed.
  final ValueChanged<String> onCompleted;

  const OtpCodeField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onCompleted,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: enabled ? () => focusNode.requestFocus() : null,
      child: ListenableBuilder(
        listenable: Listenable.merge([controller, focusNode]),
        builder: (context, _) => Stack(
          children: [
            Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                maxLength: length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                enabled: enabled,
                onChanged: (value) {
                  if (value.length == length) onCompleted(value);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < length; i++)
                  _OtpBox(
                    character: controller.text.length > i ? controller.text[i] : '',
                    isFocused: controller.text.length == i && focusNode.hasFocus,
                    isDark: isDark,
                  ),
              ],
            ),
          ],
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
    final borderColor = isFocused
        ? context.accentInk
        : (isDark ? AppColors.lineDark : AppColors.neutral200);
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
