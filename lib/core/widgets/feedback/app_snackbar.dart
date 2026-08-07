import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// Consistent snackbar styling — success / error variants.
/// Features improved border radius and icon styling.
class AppSnackbar {
  AppSnackbar._();

  static void success(BuildContext context, String message) => _show(context, message, AppColors.primary, AppIcons.check_circle_rounded, AppColors.secondaryLight);

  static void error(BuildContext context, String message) => _show(context, message, AppColors.error, AppIcons.error_rounded, Colors.white);

  static void _show(BuildContext context, String message, Color bg, AppIconData icon, Color iconColor) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(AppSizes.lg, 0, AppSizes.lg, AppSizes.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          elevation: 6,
          content: Row(
            children: [
              AppIcon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Expanded(child: Text(message, style: AppTextStyles.onDark(AppTextStyles.bodyMedium))),
            ],
          ),
        ),
      );
  }
}
