import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/misc/status_badge.dart';

class _Withdrawal {
  final String id;
  final double amount;
  final DateTime date;
  final String status;
  const _Withdrawal({required this.id, required this.amount, required this.date, required this.status});
}

/// UI-only withdrawal ledger — payout processing is out of scope for this
/// frontend build.
class WithdrawalHistoryScreen extends StatelessWidget {
  const WithdrawalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final withdrawals = [
      _Withdrawal(id: 'WD-1042', amount: 8500, date: DateTime.now().subtract(const Duration(days: 4)), status: 'completed'),
      _Withdrawal(id: 'WD-1038', amount: 5200, date: DateTime.now().subtract(const Duration(days: 18)), status: 'completed'),
      _Withdrawal(id: 'WD-1029', amount: 3100, date: DateTime.now().subtract(const Duration(days: 35)), status: 'completed'),
      _Withdrawal(id: 'WD-1015', amount: 2400, date: DateTime.now().subtract(const Duration(days: 51)), status: 'pending'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawal History')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          itemCount: withdrawals.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
          itemBuilder: (context, i) {
            final w = withdrawals[i];
            return Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSizes.radiusLg), border: Border.all(color: AppColors.line)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.secondary, size: 18),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(w.id, style: AppTextStyles.titleMedium),
                        Text(Formatters.dateShort(w.date), style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(Formatters.peso(w.amount), style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      StatusBadge.fromStatus(w.status),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
