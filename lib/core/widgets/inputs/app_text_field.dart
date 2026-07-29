import 'package:flutter/material.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';

/// Standard labeled text field used across auth, booking, and profile forms.
/// Features animated label color shift and subtle container shadow on focus.
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final int maxLines;
  final void Function(String)? onChanged;

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
    this.onChanged,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedDefaultTextStyle(
          duration: AppAnimations.fast,
          style: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w600,
            color: _focused ? AppColors.secondary : (isDark ? AppColors.textOnDark : AppColors.textPrimary),
          ),
          child: Text(widget.label),
        ),
        const SizedBox(height: 6),
        Focus(
          onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
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
              obscureText: _obscured,
              keyboardType: widget.keyboardType,
              validator: widget.validator,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              onChanged: widget.onChanged,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: widget.prefixIcon != null
                    ? Icon(widget.prefixIcon, size: 20, color: _focused ? AppColors.secondary : AppColors.neutral300)
                    : null,
                suffixIcon: widget.obscureText
                    ? IconButton(
                        icon: Icon(
                          _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20,
                          color: _focused ? AppColors.secondary : AppColors.neutral300,
                        ),
                        onPressed: () => setState(() => _obscured = !_obscured),
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
