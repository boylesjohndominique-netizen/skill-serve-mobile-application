import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/payment_qr.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/payment_qr_card.dart';
import '../../identity/controllers/identity_controller.dart';
import '../controllers/commission_controller.dart';
import '../models/commission_model.dart';
import '../services/commission_service.dart';

/// Pay the commission with a QR Ph code PayMongo makes for the exact amount.
///
/// Opening the screen asks for a code — or gets back the one already open, so
/// leaving and coming back never makes a second. The provider scans it with
/// GCash or any QR Ph app. Only PayMongo's confirmation, reaching the API by
/// its webhook, settles anything: this screen just checks every few seconds
/// and shows the result. Pops `true` once paid.
class CommissionQrScreen extends StatefulWidget {
  const CommissionQrScreen({super.key});

  @override
  State<CommissionQrScreen> createState() => _CommissionQrScreenState();
}

class _CommissionQrScreenState extends State<CommissionQrScreen> {
  static const _checkEvery = Duration(seconds: 5);

  CommissionRemittance? _payment;
  Uint8List? _qr;
  bool _loading = true;
  String? _error;
  Timer? _check;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _check?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    _check?.cancel();
    _tick?.cancel();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _show(await CommissionService().startQrPayment());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e, 'We could not create a QR code. Please try again.');
        _loading = false;
      });
    }
  }

  void _show(CommissionRemittance payment) {
    if (!mounted) return;
    final qr = payment.qrImage == null ? null : PaymentQr.decodeImage(payment.qrImage!);
    setState(() {
      _payment = payment;
      _qr = qr ?? (payment.hasPayableQr ? _qr : null);
      _loading = false;
    });

    if (payment.hasPayableQr) {
      _check ??= Timer.periodic(_checkEvery, (_) => _refresh());
      // Redraws the countdown.
      _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _check?.cancel();
      _tick?.cancel();
      _check = null;
      _tick = null;
    }

    if (payment.isConfirmed) {
      // What the provider owes and whether they can work both just changed.
      context.read<CommissionController>().load();
      context.read<IdentityController>().refreshEligibility();
    }
  }

  Future<void> _refresh() async {
    final payment = _payment;
    if (payment == null) return;
    try {
      _show(await CommissionService().getRemittance(payment.id));
    } catch (_) {
      // A missed check is retried on the next tick.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay with QR code')),
      body: SafeArea(
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pageHPad),
                child: ShimmerCardList(itemHeight: 120, count: 2),
              )
            : _error != null
                ? ErrorState(message: _error!, onRetry: _start)
                : _content(context, _payment!),
      ),
    );
  }

  Widget _content(BuildContext context, CommissionRemittance payment) {
    if (payment.isConfirmed) {
      return _Outcome(
        icon: AppIcons.check_circle_rounded,
        color: AppColors.success,
        title: 'Payment received',
        message: 'SkillServe received your ₱${payment.amountDue} (ref. ${payment.reference}). '
            'Your commission is settled.',
        action: PrimaryButton(label: 'Done', onPressed: () => context.pop(true)),
      );
    }

    if (payment.isClosedUnpaid || !payment.hasPayableQr || _qr == null) {
      return _Outcome(
        icon: AppIcons.info_outline_rounded,
        color: AppColors.warning,
        title: payment.status == 'failed' ? 'Payment did not go through' : 'This QR code has expired',
        message: payment.failureReason ?? 'Nothing was charged. Get a new QR code to pay.',
        action: PrimaryButton(label: 'Get a new QR code', onPressed: _start),
      );
    }

    final left = payment.expiresAt?.difference(DateTime.now());
    final minutes = left == null || left.isNegative ? 0 : left.inMinutes;
    final seconds = left == null || left.isNegative ? 0 : left.inSeconds % 60;

    return ListView(
      padding: const EdgeInsets.all(AppSizes.pageHPad),
      children: [
        Center(
          child: PaymentQrCard(
            image: _qr,
            amount: payment.amountDue,
            saveName: 'skillserve-commission-${payment.reference}',
            caption: 'SkillServe commission · ref. ${payment.reference}',
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        Text(
          'Scan with GCash, Maya or your bank app — any app that pays QR Ph. The amount is fixed '
          'in the code. Paying on this phone? Save the QR, then in GCash tap Pay QR → Upload QR.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSizes.md),
        Row(
          children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                'Waiting for your payment… This screen updates by itself. '
                'The code expires in $minutes:${seconds.toString().padLeft(2, '0')}.',
                style: AppTextStyles.bodySmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
        Text(
          'New work stays paused until the payment is confirmed.',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}

class _Outcome extends StatelessWidget {
  const _Outcome({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.action,
  });

  final AppIconData icon;
  final Color color;
  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSizes.pageHPad),
      children: [
        const SizedBox(height: AppSizes.xxl),
        Center(child: AppIcon(icon, size: 48, color: color)),
        const SizedBox(height: AppSizes.md),
        Text(title, style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: AppSizes.sm),
        Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSizes.xl),
        action,
      ],
    );
  }
}
