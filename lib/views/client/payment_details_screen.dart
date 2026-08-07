import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/feedback/loading_state.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../models/payment_model.dart';
import '../../services/payment_service.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

/// Full payment receipt — client, provider, method, reference, amount.
class PaymentDetailsScreen extends StatefulWidget {
  final String paymentId;
  const PaymentDetailsScreen({super.key, required this.paymentId});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  PaymentModel? _payment;

  @override
  void initState() {
    super.initState();
    PaymentService().getPaymentById(widget.paymentId).then((p) {
      if (mounted) setState(() => _payment = p);
    });
  }

  Future<void> _share() async {
    final p = _payment!;
    await Clipboard.setData(ClipboardData(
      text: 'SkillServe Receipt — ${p.id}\nBooking: ${p.bookingId}\nProvider: ${p.providerName}\n'
          'Method: ${p.method}\nReference: ${p.reference}\nAmount: ${Formatters.peso(p.amount)}\nPaid: ${Formatters.dateTime(p.paidAt)}',
    ));
    if (mounted) AppSnackbar.success(context, 'Receipt copied to clipboard.');
  }

  @override
  Widget build(BuildContext context) {
    if (_payment == null) return const Scaffold(body: LoadingState());
    final p = _payment!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Receipt header
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: p.status == PaymentStatus.paid
                            ? AppColors.successBg
                            : (p.status == PaymentStatus.refunded ? AppColors.warningBg : AppColors.errorBg),
                        shape: BoxShape.circle,
                      ),
                      child: AppIcon(
                        p.status == PaymentStatus.paid
                            ? AppIcons.check_rounded
                            : (p.status == PaymentStatus.refunded ? AppIcons.currency_exchange_rounded : AppIcons.error_rounded),
                        size: 32,
                        color: p.status == PaymentStatus.paid
                            ? AppColors.success
                            : (p.status == PaymentStatus.refunded ? AppColors.warning : AppColors.error),
                      ),
                    ).animate().scale(duration: 450.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: AppSizes.md),
                    Text(Formatters.peso(p.amount), style: AppTextStyles.onDark(AppTextStyles.monoDisplay)),
                    const SizedBox(height: 4),
                    Text('Paid via ${p.method}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark)),
                    const SizedBox(height: AppSizes.sm),
                    StatusBadge.fromStatus(p.status.name),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: AppSizes.lg),
              Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5), width: 0.8),
                  boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
                ),
                child: Column(
                  children: [
                    _row('Receipt ID', p.id, mono: true),
                    _row('Booking ref', p.bookingId, mono: true),
                    _row('Transaction ref', p.reference, mono: true),
                    Divider(height: AppSizes.xl, color: isDark ? AppColors.lineDark : AppColors.line),
                    _row('Client', p.clientName),
                    _row('Provider', p.providerName),
                    _row('Method', p.method),
                    _row('Date', Formatters.dateTime(p.paidAt)),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: AppSizes.xl),
              OutlinedAppButton(
                label: 'Share receipt',
                icon: AppIcons.ios_share_rounded,
                onPressed: _share,
              ).animate().fadeIn(delay: 260.ms, duration: 350.ms),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Share this receipt with the provider or keep it for your records.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 320.ms, duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Flexible(
            child: Text(
              value,
              style: mono ? AppTextStyles.monoMd.copyWith(color: AppColors.secondary) : AppTextStyles.titleMedium,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
