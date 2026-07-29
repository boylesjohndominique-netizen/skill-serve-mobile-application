import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.mail_outline_rounded, 'Email', 'support@skilllink.ph'),
      (Icons.call_outlined, 'Phone', '(032) 123 4567'),
      (Icons.location_on_outlined, 'Office', 'Cebu City, Philippines'),
      (Icons.schedule_outlined, 'Support hours', 'Mon–Sat, 8:00 AM – 8:00 PM'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Contact us')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Text('We\'re here to help', style: AppTextStyles.displayMedium),
            const SizedBox(height: 6),
            Text('Reach out with questions about bookings, verification, or your account.', style: AppTextStyles.bodyLarge),
            const SizedBox(height: AppSizes.xl),
            for (final item in items)
              Container(
                margin: const EdgeInsets.only(bottom: AppSizes.md),
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                      child: Icon(item.$1, color: AppColors.secondary, size: 20),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$2, style: AppTextStyles.caption),
                        Text(item.$3, style: AppTextStyles.titleMedium),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
