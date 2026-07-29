import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../buttons/outlined_app_button.dart';

/// Shown when a request fails — pairs with a retry action.
/// Features shake animation on the error icon and fade-in entrance.
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
            )
                .animate()
                .fadeIn(duration: 300.ms)
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack)
                .then(delay: 200.ms)
                .shakeX(hz: 3, amount: 4, duration: 400.ms),
            const SizedBox(height: AppSizes.lg),
            Text('Unable to load', style: AppTextStyles.titleLarge)
                .animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: AppSizes.xs),
            Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center)
                .animate().fadeIn(delay: 300.ms, duration: 350.ms),
            if (onRetry != null) ...[
              const SizedBox(height: AppSizes.lg),
              OutlinedAppButton(label: 'Try again', icon: Icons.refresh_rounded, onPressed: onRetry, fullWidth: false)
                  .animate().fadeIn(delay: 400.ms, duration: 300.ms).slideY(begin: 0.15, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}
