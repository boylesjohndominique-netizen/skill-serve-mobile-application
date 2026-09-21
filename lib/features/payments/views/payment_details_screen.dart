import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons/outlined_app_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/misc/status_badge.dart';
import '../../../core/widgets/misc/info_row.dart';
import '../../payments/controllers/payment_controller.dart';
import '../../payments/models/payment_model.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// One booking's payment: what it costs, how the customer chose to pay, and
/// whether it has been settled. Addressed by booking id — a booking is where the
/// payment record lives.
class PaymentDetailsScreen extends StatefulWidget {
  final String bookingId;
  const PaymentDetailsScreen({super.key, required this.bookingId});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  PaymentModel? _payment;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final controller = context.read<PaymentController>();
    final payment = await controller.loadPayment(widget.bookingId);
    if (!mounted) return;
    setState(() {
      _payment = payment;
      _error = payment == null ? controller.errorMessage : null;
      _loading = false;
    });
  }

  /// A summary for the customer's records — deliberately not called a receipt,
  /// because nothing was charged through the app.
  Future<void> _copySummary() async {
    final p = _payment!;
    await Clipboard.setData(ClipboardData(
      text: 'SkillServe booking ${p.bookingNumber}\n'
          'Service: ${p.serviceTitle}\n'
          'Provider: ${p.providerName}\n'
          'Payment method: ${p.method}\n'
          'Amount: ${Formatters.peso(p.amount)}\n'
          'Status: ${p.statusLabel}\n'
          'Scheduled: ${Formatters.dateTime(p.date)}',
    ));
    if (mounted) AppSnackbar.success(context, 'Payment summary copied.');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingState());

    final p = _payment;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: SafeArea(
          child: ErrorState(
            message: _error ?? 'This payment could not be loaded.',
            onRetry: _load,
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (tint, fg, icon) = switch (p.status) {
      PaymentStatus.paid => (AppColors.successBg, AppColors.success, AppIcons.check_rounded),
      PaymentStatus.refunded ||
      PaymentStatus.partiallyRefunded =>
        (AppColors.warningBg, AppColors.warning, AppIcons.currency_exchange_rounded),
      PaymentStatus.notDue => (AppColors.neutral100, AppColors.neutral400, AppIcons.close_rounded),
      PaymentStatus.unpaid => (AppColors.secondarySoft, AppColors.secondaryDeep, AppIcons.hourglass_top_rounded),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.xl, horizontal: AppSizes.lg),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
                      child: AppIcon(icon, size: 32, color: fg),
                    ).animate().scale(duration: 450.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: AppSizes.md),
                    Text(Formatters.peso(p.amount),
                        style: AppTextStyles.onDark(AppTextStyles.monoDisplay)),
                    const SizedBox(height: 4),
                    Text(
                      p.status == PaymentStatus.notDue
                          ? 'Booking cancelled — nothing to pay'
                          : 'Pay by ${p.method}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    StatusBadge(
                      label: p.statusLabel,
                      tone: StatusBadge.fromStatus(p.statusKey).tone,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: AppSizes.lg),
              Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(
                      color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5),
                      width: 0.8),
                ),
                child: Column(
                  children: [
                    InfoRow(
                      label: 'Booking',
                      value: p.bookingNumber.isEmpty ? p.bookingId : p.bookingNumber,
                      mono: true,
                      emphasize: true,
                    ),
                    InfoRow(label: 'Service', value: p.serviceTitle.isEmpty ? '—' : p.serviceTitle),
                    InfoRow(label: 'Provider', value: p.providerName.isEmpty ? '—' : p.providerName),
                    Divider(height: AppSizes.xl, color: isDark ? AppColors.lineDark : AppColors.line),
                    InfoRow(label: 'Method', value: p.method),
                    InfoRow(label: 'Scheduled', value: Formatters.dateTime(p.date)),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: AppSizes.md),
              Text(
                'Payment is settled directly with your provider. SkillServe records the '
                'method you chose and whether the booking has been paid.',
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.xl),
              OutlinedAppButton(
                label: 'View booking',
                icon: AppIcons.calendar_month_rounded,
                onPressed: () => context.push('/booking-details/${p.bookingId}'),
              ),
              const SizedBox(height: AppSizes.sm),
              OutlinedAppButton(
                label: 'Copy summary',
                icon: AppIcons.ios_share_rounded,
                onPressed: _copySummary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
