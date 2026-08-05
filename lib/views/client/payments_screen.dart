import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/payment_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/widgets/misc/status_badge.dart';

IconData _methodIcon(String method) {
  switch (method) {
    case 'GCash':
    case 'Maya':
      return Icons.account_balance_wallet_rounded;
    case 'Card':
      return Icons.credit_card_rounded;
    default:
      return Icons.payments_outlined;
  }
}

/// Client payment history — every transaction with method, status, and ref.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentController>().loadPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaymentController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: SafeArea(
        child: controller.isLoading
            ? const Padding(padding: EdgeInsets.all(AppSizes.pageHPad), child: ShimmerCardList(itemHeight: 84))
            : controller.payments.isEmpty
                ? const EmptyState(icon: Icons.receipt_long_outlined, title: 'No payments yet', message: 'Your payment history will appear here.')
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.pageHPad),
                    itemCount: controller.payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                    itemBuilder: (context, i) {
                      final p = controller.payments[i];
                      return InkWell(
                        onTap: () => context.push('/payment-details/${p.id}'),
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        child: Container(
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
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                ),
                                child: Icon(_methodIcon(p.method), size: 18, color: AppColors.secondary),
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.method, style: AppTextStyles.titleMedium),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${p.id} · ${Formatters.dateShort(p.paidAt)}',
                                      style: AppTextStyles.monoSm.copyWith(color: AppColors.neutral300),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(Formatters.peso(p.amount), style: AppTextStyles.monoMd.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  StatusBadge.fromStatus(p.status.name),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                          .slideY(begin: 0.05, end: 0);
                    },
                  ),
      ),
    );
  }
}
