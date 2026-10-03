import 'package:flutter/material.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// Standard labeled text field used across auth, booking, and profile forms.
/// Features animated label color shift and subtle container shadow on focus.
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final AppIconData? prefixIcon;
  final int maxLines;

  /// Hard cap on the number of characters, matching the API's limit so a value
  /// that would be rejected cannot be typed. The counter stays hidden.
  final int? maxLength;
  final void Function(String)? onChanged;

  /// Set false while a request is in flight so the value cannot change
  /// under the submission that is already using it.
  final bool enabled;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: AppAnimations.fast,
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w600,
            color: !widget.enabled
                ? muted
                : (_focused ? context.accentInk : (isDark ? AppColors.textOnDark : AppColors.textPrimary)),
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: 6),
        Focus(
          onFocusChange: (hasFocus) =>
              setState(() => _focused = hasFocus && widget.enabled),
          child: AnimatedContainer(
            duration: AppAnimations.md,
            curve: AppAnimations.defaultCurve,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: TextFormField(
              controller: widget.controller,
              enabled: widget.enabled,
              obscureText: _obscured,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              maxLength: widget.maxLength,
              onChanged: widget.onChanged,
              style: AppTextStyles.bodyLarge.copyWith(
                color: widget.enabled ? null : muted,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                // The cap is enforced, not advertised — the field keeps its
                // shape whether or not a limit is set.
                counterText: '',
                prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                prefixIcon: widget.prefixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.only(left: 14, right: 10),
                        child: AppIcon(
                          widget.prefixIcon,
                          size: 18,
                          strokeWidth: 1.5,
                          color: _focused ? context.accentInk : (isDark ? AppColors.textMutedDark : AppColors.textMuted),
                        ),
                      )
                    : null,
                suffixIcon: widget.obscureText
                    ? IconButton(
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        icon: AppIcon(
                          _obscured ? AppIcons.visibility_off_outlined : AppIcons.visibility_outlined,
                          size: 18,
                          strokeWidth: 1.5,
                          color: _focused ? context.accentInk : (isDark ? AppColors.textMutedDark : AppColors.textMuted),
                        ),
                        onPressed: widget.enabled
                            ? () => setState(() => _obscured = !_obscured)
                            : null,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
