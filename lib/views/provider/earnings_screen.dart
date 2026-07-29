import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../data/mock/mock_data.dart';
import '../../models/booking_model.dart';

/// Earnings summary — completed-job payouts. Payment processing itself is
/// out of scope (handled outside the app per the project brief); this is
/// a read-only ledger view.
class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final completed = MockData.bookingsForProvider.where((b) => b.status == BookingStatus.completed).toList();
    final total = completed.fold<double>(0, (sum, b) => sum + b.amount);
    final thisMonth = completed
        .where((b) => b.bookingDate.month == DateTime.now().month)
        .fold<double>(0, (sum, b) => sum + b.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.xl),
              decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
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
            ),
            const SizedBox(height: AppSizes.lg),
            OutlinedAppButton(
              label: 'View withdrawal history',
              icon: Icons.history_rounded,
              onPressed: () => context.push('/withdrawal-history'),
            ),
            const SizedBox(height: AppSizes.xl),
            Text('Payout history', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizes.md),
            for (final b in completed)
              Container(
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.radiusLg), border: Border.all(color: AppColors.line)),
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
                          Text(b.serviceTitle, style: AppTextStyles.titleMedium),
                          Text('${b.clientName} • ${Formatters.dateShort(b.bookingDate)}', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    Text('+${Formatters.peso(b.amount)}', style: AppTextStyles.titleMedium.copyWith(color: AppColors.success)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
