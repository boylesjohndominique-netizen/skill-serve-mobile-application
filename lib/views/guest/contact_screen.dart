import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    const items = [
      (AppIcons.mail_outline_rounded, 'Email', 'support@skillserve.ph'),
      (AppIcons.call_outlined, 'Phone', '(032) 123 4567'),
      (AppIcons.location_on_outlined, 'Office', 'Cebu City, Philippines'),
      (AppIcons.schedule_outlined, 'Support hours', 'Mon–Sat, 8:00 AM – 8:00 PM'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Contact us')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Text("We're here to help", style: AppTextStyles.displayMedium)
                .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
            const SizedBox(height: 6),
            Text('Reach out with questions about bookings, verification, or your account.', style: AppTextStyles.bodyLarge)
                .animate().fadeIn(delay: 80.ms, duration: 300.ms),
            const SizedBox(height: AppSizes.xl),
            for (var i = 0; i < items.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: AppSizes.md),
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
                  boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: AppIcon(items[i].$1, color: AppColors.secondary, size: 20),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].$2, style: AppTextStyles.caption),
                        Text(items[i].$3, style: AppTextStyles.titleMedium),
                      ],
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 150 + i * 80), duration: 350.ms)
                  .slideY(begin: 0.06, end: 0),
          ],
        ),
      ),
    );
  }
}
