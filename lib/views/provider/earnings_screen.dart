import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../data/mock/mock_data.dart';
import '../../models/booking_model.dart';

/// Earnings summary — completed-job payouts.
class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final completed = MockData.bookingsForProvider.where((b) => b.status == BookingStatus.completed).toList();
    final total = completed.fold<double>(0, (sum, b) => sum + b.amount);
    final thisMonth = completed
        .where((b) => b.bookingDate.month == DateTime.now().month)
        .fold<double>(0, (sum, b) => sum + b.amount);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.xl),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total earnings', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark)),
                  const SizedBox(height: 4),
                  Text(Formatters.peso(total), style: AppTextStyles.onDark(AppTextStyles.displayLarge)),
                  const SizedBox(height: AppSizes.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('This month: ${Formatters.peso(thisMonth)}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark)),
                      Text('${completed.length} completed jobs', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
            const SizedBox(height: AppSizes.lg),
            OutlinedAppButton(
              label: 'View withdrawal history',
              icon: Icons.history_rounded,
              onPressed: () => context.push('/withdrawal-history'),
            ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
            const SizedBox(height: AppSizes.xl),
            Text('Payout history', style: AppTextStyles.titleLarge)
                .animate().fadeIn(delay: 220.ms, duration: 300.ms),
            const SizedBox(height: AppSizes.md),
            for (var i = 0; i < completed.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5), width: 0.8),
                  boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                      child: const Icon(Icons.arrow_downward_rounded, color: AppColors.success, size: 16),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(completed[i].serviceTitle, style: AppTextStyles.titleMedium),
                          Text('${completed[i].clientName} • ${Formatters.dateShort(completed[i].bookingDate)}', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    Text('+${Formatters.peso(completed[i].amount)}', style: AppTextStyles.titleMedium.copyWith(color: AppColors.success)),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 300 + i.clamp(0, 8) * 60), duration: 350.ms)
                  .slideY(begin: 0.05, end: 0),
          ],
        ),
      ),
    );
  }
}
