import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../buttons/outlined_app_button.dart';

/// Shown when a request fails — pairs with a retry action.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, this.message = "Something went wrong. Please try again.", this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.errorBg, shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, size: 30, color: AppColors.error),
            ),
            const SizedBox(height: AppSizes.lg),
            Text('Unable to load', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizes.xs),
            Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.lg),
              OutlinedAppButton(label: 'Try again', icon: Icons.refresh_rounded, onPressed: onRetry, fullWidth: false),
            ],
          ],
        ),
      ),
    );
  }
}
