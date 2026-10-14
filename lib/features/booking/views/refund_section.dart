import 'package:flutter/material.dart';

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
import '../../../core/widgets/misc/private_image.dart';
import '../../../core/widgets/misc/status_badge.dart';

/// What the provider sends back: an optional GCash reference and the
/// screenshot that proves it.
typedef RefundProofDraft = ({String reference, String screenshotPath});

/// A cancelled booking's payment going back to the customer. The provider
/// returns it with proof by the deadline; the customer confirms it arrived or
/// reports that it did not, and SkillServe settles the rest.
class RefundSection extends StatelessWidget {
  final BookingRefund refund;
  final bool isProviderView;
  final bool isDark;
  final bool busy;

  /// Provider: upload proof of returning it.
  final VoidCallback? onMarkSent;

  /// Customer: it arrived / it did not.
  final VoidCallback? onConfirm;
  final VoidCallback? onNotReceived;

  const RefundSection({
    super.key,
    required this.refund,
    required this.isProviderView,
    required this.isDark,
    this.busy = false,
    this.onMarkSent,
    this.onConfirm,
    this.onNotReceived,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;
    final amount = Formatters.peso(refund.amount);
    final due = refund.dueBy == null ? '' : Formatters.dateTime(refund.dueBy!);
    final (label, tone) = switch (refund.status) {
      _ when refund.isOverdue => ('Overdue', StatusTone.error),
      'sent' => ('Returned', StatusTone.info),
      'confirmed' => ('Received', StatusTone.success),
      'not_received' => ('Not received', StatusTone.error),
      'resolved' => refund.resolution == 'returned' ? ('Settled', StatusTone.success) : ('Not returned', StatusTone.error),
      _ => ('To return', StatusTone.warning),
    };

    final message = isProviderView
        ? switch (refund.status) {
            _ when refund.isOverdue =>
              'You did not return $amount by $due. You cannot take new bookings until you return it and upload the proof.',
            'due' => 'This booking was cancelled after the customer paid. Return $amount to them in GCash by $due and upload the proof.',
            'sent' => 'You returned $amount. Waiting for the customer to confirm it arrived.',
            'confirmed' => 'The customer confirmed receiving $amount.',
            'not_received' =>
              'The customer says the $amount did not arrive. SkillServe is reviewing it, and you cannot take new bookings until it is settled. If you did return it, upload clearer proof.',
            _ => refund.resolution == 'returned'
                ? 'SkillServe confirmed you returned $amount.'
                : 'SkillServe found $amount was not returned. ${refund.resolutionNote ?? ''}',
          }
        : switch (refund.status) {
            'due' => refund.isOverdue
                ? 'The provider has not returned your $amount by the deadline. SkillServe has been told and is following it up.'
                : 'This booking was cancelled, so the provider must return your $amount by $due.',
            'sent' => 'The provider says they returned $amount. Check your GCash, then confirm it — or tell us it did not arrive.',
            'confirmed' => 'You confirmed receiving $amount.',
            'not_received' => 'You reported that $amount did not arrive. SkillServe is reviewing it.',
            _ => refund.resolution == 'returned'
                ? 'SkillServe confirmed your $amount was returned.'
                : 'SkillServe found your $amount was not returned and is acting on the provider\'s account. ${refund.resolutionNote ?? ''}',
          };

    final canMarkSent = isProviderView && (refund.isDue || refund.isNotReceived);
    final canAnswer = !isProviderView && refund.isSent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: refund.isOverdue || refund.isNotReceived ? context.errorColor : lineColor.withValues(alpha: 0.5),
          width: 0.8,
        ),
        boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(isProviderView ? 'Payment to return' : 'Your refund', style: AppTextStyles.titleLarge),
              ),
              StatusBadge(label: label, tone: tone),
            ],
          ),
          const SizedBox(height: 4),
          Text(message, style: AppTextStyles.bodyMedium),
          if (refund.proofUrl != null) ...[
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                _ProofThumbnail(url: refund.proofUrl!),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Text(
                    [
                      'Proof of the transfer',
                      if ((refund.reference ?? '').isNotEmpty) 'Ref ${refund.reference}',
                      if (refund.sentAt != null) Formatters.relative(refund.sentAt!),
                    ].join(' · '),
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          if (refund.isNotReceived && (refund.customerNote ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            Text('Customer: ${refund.customerNote}', style: AppTextStyles.bodySmall.copyWith(color: context.errorColor)),
          ],
          if (canMarkSent) ...[
            const SizedBox(height: AppSizes.md),
            PrimaryButton(
              label: refund.isNotReceived ? 'Upload new proof' : "I've returned it — upload proof",
              icon: AppIcons.currency_exchange_rounded,
              isLoading: busy,
              onPressed: busy ? null : onMarkSent,
            ),
          ],
          if (canAnswer) ...[
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedAppButton(
                    label: 'Not received',
                    icon: AppIcons.close_rounded,
                    color: AppColors.error,
                    onPressed: busy ? null : onNotReceived,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: PrimaryButton(
                    label: 'I received it',
                    icon: AppIcons.check_rounded,
                    isLoading: busy,
                    onPressed: busy ? null : onConfirm,
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

/// The transfer screenshot; a tap opens it full size.
class _ProofThumbnail extends StatelessWidget {
  final String url;
  const _ProofThumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Refund proof. Open full size',
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: const Text('Refund proof', style: TextStyle(color: Colors.white, fontSize: 15)),
            ),
            body: InteractiveViewer(maxScale: 4, child: Center(child: PrivateImage(url: url, fit: BoxFit.contain))),
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

/// Asks the provider for the proof of returning [amount]. Null when they back out.
Future<RefundProofDraft?> showRefundProofSheet(BuildContext context, {required double amount}) {
  return AppBottomSheet.show<RefundProofDraft>(context, child: _RefundProofForm(amount: amount));
}

class _RefundProofForm extends StatefulWidget {
  final double amount;
  const _RefundProofForm({required this.amount});

  @override
  State<_RefundProofForm> createState() => _RefundProofFormState();
}

class _RefundProofFormState extends State<_RefundProofForm> {
  final _reference = TextEditingController();
  List<String> _screenshot = const [];

  @override
  void dispose() {
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload refund proof', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Send ${Formatters.peso(widget.amount)} back to the customer in GCash, then attach the screenshot. The customer confirms it once it arrives.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSizes.lg),
            AppTextField(
              label: 'GCash reference number (optional)',
              hint: 'From the GCash receipt',
              controller: _reference,
              maxLength: 100,
            ),
            const SizedBox(height: AppSizes.md),
            Text('Screenshot of the transfer', style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            PhotoAttachmentsField(
              paths: _screenshot,
              max: 1,
              helper: 'Required · the GCash receipt showing the amount sent to the customer',
              onChanged: (photos) => setState(() => _screenshot = photos),
            ),
            const SizedBox(height: AppSizes.xl),
            PrimaryButton(
              label: 'Send proof',
              icon: AppIcons.send_rounded,
              onPressed: _screenshot.isEmpty
                  ? null
                  : () => Navigator.of(context).pop<RefundProofDraft>((
                        reference: _reference.text.trim(),
                        screenshotPath: _screenshot.first,
                      )),
            ),
          ],
        ),
      ),
    );
  }
}
