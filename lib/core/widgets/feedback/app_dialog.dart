import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../buttons/primary_button.dart';
import '../buttons/danger_button.dart';
import '../inputs/app_text_field.dart';

/// Confirmation dialog used for destructive or important actions
/// (cancel booking, log out, delete portfolio item…).
/// Features scale + fade entrance animation and backdrop blur.
class AppDialog {
  AppDialog._();

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    bool danger = false,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 3 * animation.value,
            sigmaY: 3 * animation.value,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;

        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(AppSizes.xl),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: AppSizes.shadowLg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleLarge),
                  const SizedBox(height: AppSizes.sm),
                  Text(message, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSizes.xl),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel', style: AppTextStyles.button.copyWith(
                            color: isDark ? AppColors.textMutedDark : AppColors.textSecondary,
                          )),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: danger
                            ? DangerButton(
                                label: confirmLabel,
                                onPressed: () => Navigator.of(context).pop(true),
                              )
                            : PrimaryButton(
                                label: confirmLabel,
                                onPressed: () => Navigator.of(context).pop(true),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  /// Confirmation dialog with one optional free-text field — used where the
  /// API accepts a reason (cancelling a booking, declining a request).
  ///
  /// Returns null when the person backed out, otherwise the trimmed text.
  /// The text may be empty unless [minLength] is set, which keeps the confirm
  /// button disabled until the answer is at least that long — for the reasons
  /// the API requires.
  static Future<String?> prompt(
    BuildContext context, {
    required String title,
    required String message,
    required String fieldLabel,
    String? hint,
    String confirmLabel = 'Confirm',
    bool danger = false,
    int maxLength = 1000,
    int minLength = 0,
  }) {
    return showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3 * animation.value, sigmaY: 3 * animation.value),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) => _PromptDialog(
        title: title,
        message: message,
        fieldLabel: fieldLabel,
        hint: hint,
        confirmLabel: confirmLabel,
        danger: danger,
        maxLength: maxLength,
        minLength: minLength,
      ),
    );
  }
}

class _PromptDialog extends StatefulWidget {
  final String title;
  final String message;
  final String fieldLabel;
  final String? hint;
  final String confirmLabel;
  final bool danger;
  final int maxLength;
  final int minLength;

  const _PromptDialog({
    required this.title,
    required this.message,
    required this.fieldLabel,
    required this.hint,
    required this.confirmLabel,
    required this.danger,
    required this.maxLength,
    required this.minLength,
  });

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(AppSizes.xl),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              boxShadow: AppSizes.shadowLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: AppTextStyles.titleLarge),
                const SizedBox(height: AppSizes.sm),
                Text(widget.message, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: widget.fieldLabel,
                  hint: widget.hint,
                  controller: _controller,
                  maxLines: 3,
                ),
                const SizedBox(height: AppSizes.xl),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel', style: AppTextStyles.button.copyWith(
                          color: isDark ? AppColors.textMutedDark : AppColors.textSecondary,
                        )),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (context, value, _) {
                          final onPressed =
                              value.text.trim().length >= widget.minLength ? _submit : null;
                          return widget.danger
                              ? DangerButton(label: widget.confirmLabel, onPressed: onPressed)
                              : PrimaryButton(label: widget.confirmLabel, onPressed: onPressed);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
