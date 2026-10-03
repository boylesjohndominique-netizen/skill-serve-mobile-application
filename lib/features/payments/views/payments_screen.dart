import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../payments/controllers/payment_controller.dart';
import '../models/payment_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/status_badge.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

AppIconData methodIcon(String? code) {
  switch (code) {
    case 'gcash':
    case 'paypal':
    case 'bank_transfer':
      return AppIcons.account_balance_wallet_rounded;
    case 'credit_card':
    case 'debit_card':
      return AppIcons.credit_card_rounded;
    default:
      return AppIcons.payments_outlined;
  }
}

/// The customer's payment history: what each booking cost, how they chose to
/// pay, and whether it has been settled.
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

  Future<void> _reload() => context.read<PaymentController>().loadPayments();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaymentController>();
    final failed = controller.errorMessage != null && controller.payments.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: SafeArea(
        child: controller.isLoading
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pageHPad),
                child: ShimmerCardList(itemHeight: 72),
              )
            : failed
                ? ErrorState(message: controller.errorMessage!, onRetry: _reload)
                : RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSizes.pageHPad),
                      children: [
                        _SettlementNote(
                          outstanding: controller.outstanding,
                          settled: controller.settled,
                        ).animate().fadeIn(duration: 300.ms),
                        const SizedBox(height: AppSizes.lg),
                        if (controller.payments.isEmpty)
                          const EmptyState(
                            icon: AppIcons.receipt_long_outlined,
                            title: 'No payments yet',
                            message: 'Each booking you make will show its payment here.',
                          )
                        else
                          for (var i = 0; i < controller.payments.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSizes.sm),
                              child: _PaymentRow(payment: controller.payments[i])
                                  .animate()
                                  .fadeIn(
                                      delay: Duration(milliseconds: i.clamp(0, 8) * 60),
                                      duration: 350.ms)
                                  .slideY(begin: 0.05, end: 0),
                            ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

/// Totals, plus the one fact every customer needs: money moves between them and
/// the provider, not through the app.
class _SettlementNote extends StatelessWidget {
  final double outstanding;
  final double settled;

  const _SettlementNote({required this.outstanding, required this.settled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Total(label: 'Still to pay', value: Formatters.peso(outstanding)),
              ),
              Expanded(
                child: _Total(label: 'Paid', value: Formatters.peso(settled)),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'You pay your provider directly using the method you chose when booking. '
            'SkillServe does not charge your card or wallet.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark),
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  final String label;
  final String value;
  const _Total({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark)),
        const SizedBox(height: 2),
        Text(value, style: AppTextStyles.onDark(AppTextStyles.titleLarge)),
      ],
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return InkWell(
      onTap: () => context.push('/payment-details/${payment.bookingId}'),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
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
              child: AppIcon(methodIcon(payment.methodCode), size: 18, color: context.accentInk),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.serviceTitle.isEmpty ? 'Booking' : payment.serviceTitle,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${payment.method} · ${Formatters.dateShort(payment.date)}',
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Formatters.peso(payment.amount),
                    style: AppTextStyles.monoMd.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                StatusBadge(
                  label: payment.statusLabel,
                  tone: StatusBadge.fromStatus(payment.statusKey).tone,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
