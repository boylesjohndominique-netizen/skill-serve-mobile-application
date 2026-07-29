import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';

/// Shown when a list/screen has no content yet (no bookings, no messages…).
/// Features a gentle breathe animation on the icon and fade-in entrance.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

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
              decoration: const BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: AppColors.neutral300),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack)
                .then()
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.06, duration: const Duration(milliseconds: 2000), curve: Curves.easeInOut),
            const SizedBox(height: AppSizes.lg),
            Text(title, style: AppTextStyles.titleLarge, textAlign: TextAlign.center)
                .animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: AppSizes.xs),
            Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center)
                .animate().fadeIn(delay: 250.ms, duration: 350.ms),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSizes.lg),
              TextButton(onPressed: onAction, child: Text(actionLabel!))
                  .animate().fadeIn(delay: 350.ms, duration: 300.ms),
            ],
          ],
        ),
      ),
    );
  }
}
