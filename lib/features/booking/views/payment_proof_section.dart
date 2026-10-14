import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/booking_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons/outlined_app_button.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_bottom_sheet.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/photo_attachments_field.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/private_image.dart';
import '../../../core/widgets/misc/status_badge.dart';

/// What the customer paid in GCash and the screenshot that shows it.
typedef PaymentProofDraft = ({double amount, String reference, String screenshotPath});

/// The GCash payments on a booking: what has been confirmed, what is still to
/// pay, and every proof the customer sent. The customer sends proof from
/// here; the provider opens the screenshot and confirms or rejects it.
class PaymentProofSection extends StatelessWidget {
  final BookingModel booking;
  final bool isProviderView;
  final bool isDark;

  /// A request is running; the buttons wait.
  final bool busy;

  final VoidCallback? onSendProof;
  final void Function(PaymentProof proof)? onConfirm;
  final void Function(PaymentProof proof)? onReject;

  const PaymentProofSection({
    super.key,
    required this.booking,
    required this.isProviderView,
    required this.isDark,
    this.busy = false,
    this.onSendProof,
    this.onConfirm,
    this.onReject,
  });

  /// Whether there is anything for this side to see or do here.
  static bool appliesTo(BookingModel booking, {required bool isProviderView}) =>
      booking.paymentProofs.isNotEmpty ||
      booking.amountPaid > 0 ||
      (!isProviderView && booking.canSendPaymentProof);

  @override
  Widget build(BuildContext context) {
    final pending = booking.pendingProof;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
        boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('GCash payments', style: AppTextStyles.titleLarge),
          const SizedBox(height: 4),
          Text(
            booking.isOwing
                ? 'Paid ${Formatters.peso(booking.amountPaid)} of ${Formatters.peso(booking.amount)} · '
                    '${Formatters.peso(booking.balanceDue)} still to pay'
                : 'Fully paid · ${Formatters.peso(booking.amount)}',
            style: AppTextStyles.bodyMedium,
          ),
          if (booking.paymentProofs.isNotEmpty) ...[
            const SizedBox(height: AppSizes.md),
            for (final proof in booking.paymentProofs)
              _ProofRow(
                proof: proof,
                isProviderView: isProviderView,
                busy: busy,
                // The provider confirms only what is still owed.
                onConfirm: proof.isPending && booking.isOwing && proof.amount <= booking.balanceDue + 0.001
                    ? onConfirm
                    : null,
                onReject: proof.isPending ? onReject : null,
              ),
          ],
          if (!isProviderView) ...[
            const SizedBox(height: AppSizes.md),
            if (pending != null)
              Text(
                'Waiting for the provider to confirm ${Formatters.peso(pending.amount)}. You will be told as soon as they do.',
                style: AppTextStyles.bodySmall,
              )
            else if (booking.canSendPaymentProof)
              PrimaryButton(
                label: "I've paid — send proof",
                icon: AppIcons.receipt_long_outlined,
                isLoading: busy,
                onPressed: busy ? null : onSendProof,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProofRow extends StatelessWidget {
  final PaymentProof proof;
  final bool isProviderView;
  final bool busy;
  final void Function(PaymentProof proof)? onConfirm;
  final void Function(PaymentProof proof)? onReject;

  const _ProofRow({
    required this.proof,
    required this.isProviderView,
    required this.busy,
    this.onConfirm,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (proof.status) {
      'confirmed' => ('Confirmed', StatusTone.success),
      'rejected' => ('Not accepted', StatusTone.error),
      _ => ('Waiting', StatusTone.warning),
    };
    final showActions = isProviderView && (onConfirm != null || onReject != null);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Screenshot(url: proof.imageUrl),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(Formatters.peso(proof.amount), style: AppTextStyles.titleMedium)),
                        StatusBadge(label: label, tone: tone),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (proof.createdAt != null) 'Sent ${Formatters.relative(proof.createdAt!)}',
                        if ((proof.reference ?? '').isNotEmpty) 'Ref ${proof.reference}',
                      ].join(' · '),
                      style: AppTextStyles.bodySmall,
                    ),
                    if (proof.isRejected && (proof.reviewNote ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(proof.reviewNote!, style: AppTextStyles.bodySmall.copyWith(color: context.errorColor)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (showActions) ...[
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                if (onReject != null)
                  Expanded(
                    child: OutlinedAppButton(
                      label: 'Reject',
                      icon: AppIcons.close_rounded,
                      color: AppColors.error,
                      onPressed: busy ? null : () => onReject!(proof),
                    ),
                  ),
                if (onReject != null && onConfirm != null) const SizedBox(width: AppSizes.sm),
                if (onConfirm != null)
                  Expanded(
                    child: PrimaryButton(
                      label: 'Confirm',
                      icon: AppIcons.check_rounded,
                      isLoading: busy,
                      onPressed: busy ? null : () => onConfirm!(proof),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The payment screenshot as a thumbnail; a tap opens it full size.
class _Screenshot extends StatelessWidget {
  final String? url;
  const _Screenshot({required this.url});

  @override
  Widget build(BuildContext context) {
    final url = this.url;
    if (url == null) {
      return const SizedBox(width: 56, height: 56);
    }
    return Semantics(
      button: true,
      label: 'Payment screenshot. Open full size',
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: const Text('Payment screenshot', style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
            body: InteractiveViewer(
              maxScale: 4,
              child: Center(child: PrivateImage(url: url, fit: BoxFit.contain)),
            ),
          ),
        )),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: PrivateImage(url: url, width: 56, height: 56),
        ),
      ),
    );
  }
}

/// Asks what the customer paid — the whole [balance] or a downpayment — and
/// for the screenshot. Null when they back out.
Future<PaymentProofDraft?> showSendPaymentProofSheet(BuildContext context, {required double balance}) {
  return AppBottomSheet.show<PaymentProofDraft>(context, child: _SendProofForm(balance: balance));
}

class _SendProofForm extends StatefulWidget {
  final double balance;
  const _SendProofForm({required this.balance});

  @override
  State<_SendProofForm> createState() => _SendProofFormState();
}

class _SendProofFormState extends State<_SendProofForm> {
  late final _amount = TextEditingController(text: widget.balance.toStringAsFixed(2));
  final _reference = TextEditingController();
  List<String> _screenshot = const [];

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(_amount.text.replaceAll(',', '').trim());

  /// Says what is wrong with the amount, once something was typed.
  String? get _amountError {
    final text = _amount.text.trim();
    if (text.isEmpty) return null;
    final value = _value;
    if (value == null || value < 1) return 'Enter the amount you sent, at least ₱1.';
    if (value > widget.balance + 0.001) return 'At most ${Formatters.peso(widget.balance)} is still to pay.';
    return null;
  }

  bool get _canSend => _value != null && _amountError == null && _screenshot.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final value = _value ?? 0;
    final isDownpayment = value > 0 && value < widget.balance - 0.001;

    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Send payment proof', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Tell the provider what you sent in GCash and attach the screenshot. They confirm it once it reaches them.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSizes.lg),
            AppTextField(
              label: 'Amount sent',
              hint: 'e.g. ${widget.balance.toStringAsFixed(2)}',
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              prefixIcon: AppIcons.account_balance_wallet_rounded,
              errorText: _amountError,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSizes.xs),
            Wrap(
              spacing: AppSizes.sm,
              children: [
                ActionChip(
                  label: Text('Full ${Formatters.peso(widget.balance)}'),
                  onPressed: () => setState(() => _amount.text = widget.balance.toStringAsFixed(2)),
                ),
                if (widget.balance >= 2)
                  ActionChip(
                    label: Text('Half ${Formatters.peso((widget.balance / 2).floorToDouble())}'),
                    onPressed: () => setState(() => _amount.text = (widget.balance / 2).floorToDouble().toStringAsFixed(2)),
                  ),
              ],
            ),
            if (isDownpayment) ...[
              const SizedBox(height: AppSizes.xs),
              Text(
                'A downpayment: ${Formatters.peso(widget.balance - value)} will still be to pay.',
                style: AppTextStyles.bodySmall.copyWith(color: context.accentInk),
              ),
            ],
            const SizedBox(height: AppSizes.md),
            AppTextField(
              label: 'GCash reference number (optional)',
              hint: 'From the GCash receipt',
              controller: _reference,
              maxLength: 100,
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                const AppIcon(AppIcons.photo_library_outlined, size: 18),
                const SizedBox(width: 6),
                Text('Screenshot of the payment', style: AppTextStyles.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            PhotoAttachmentsField(
              paths: _screenshot,
              max: 1,
              helper: 'Required · the GCash receipt showing the amount and reference',
              onChanged: (photos) => setState(() => _screenshot = photos),
            ),
            const SizedBox(height: AppSizes.xl),
            PrimaryButton(
              label: 'Send to provider',
              icon: AppIcons.send_rounded,
              onPressed: _canSend
                  ? () => Navigator.of(context).pop<PaymentProofDraft>((
                        amount: double.parse(_value!.toStringAsFixed(2)),
                        reference: _reference.text.trim(),
                        screenshotPath: _screenshot.first,
                      ))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
