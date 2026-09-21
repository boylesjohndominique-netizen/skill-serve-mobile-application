import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/report_controller.dart';
import '../models/report_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/inputs/app_text_field.dart';

/// Report a review or a message: pick a reason, say why, send.
///
/// Pass exactly one of [reviewId] or [messageId]. The API decides who it is
/// about, and refuses your own review or a message you did not receive.
Future<void> showReportContentSheet(
  BuildContext context, {
  String? reviewId,
  String? messageId,
  required String title,
}) {
  assert((reviewId == null) != (messageId == null), 'Report one subject.');

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor:
        Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
    ),
    builder: (sheetContext) => _ReportContentSheet(
      reviewId: reviewId,
      messageId: messageId,
      title: title,
    ),
  );
}

class _ReportContentSheet extends StatefulWidget {
  final String? reviewId;
  final String? messageId;
  final String title;

  const _ReportContentSheet({required this.reviewId, required this.messageId, required this.title});

  @override
  State<_ReportContentSheet> createState() => _ReportContentSheetState();
}

class _ReportContentSheetState extends State<_ReportContentSheet> {
  final _details = TextEditingController();
  ReportReason? _reason;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  bool get _canSubmit => _reason != null && _details.text.trim().length >= 10;

  Future<void> _submit() async {
    final reports = context.read<ReportController>();
    final report = await reports.fileReport(
      reviewId: widget.reviewId,
      messageId: widget.messageId,
      reason: _reason!,
      details: _details.text.trim(),
    );
    if (!mounted) return;

    if (report == null) {
      AppSnackbar.error(context, reports.errorMessage ?? 'Unable to send this report.');
      return;
    }
    Navigator.of(context).pop();
    AppSnackbar.success(context, 'Thanks — our team will review it. Track it in My Reports.');
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.watch<ReportController>().isSubmitting;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.xl,
        right: AppSizes.xl,
        top: AppSizes.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.xl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: AppTextStyles.titleLarge),
            const SizedBox(height: 4),
            Text('Reports go to our moderators, not to the person you are reporting.',
                style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSizes.lg),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final reason in ReportReason.forContent)
                  ChoiceChip(
                    label: Text(reason.label),
                    selected: _reason == reason,
                    selectedColor: AppColors.secondary,
                    showCheckmark: false,
                    labelStyle: AppTextStyles.label.copyWith(
                      color: _reason == reason ? AppColors.primary : null,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) => setState(() => _reason = reason),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),
            AppTextField(
              label: 'What is wrong with it?',
              hint: 'At least 10 characters',
              controller: _details,
              maxLines: 3,
              maxLength: 2000,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSizes.lg),
            PrimaryButton(
              label: 'Send report',
              isLoading: submitting,
              onPressed: _canSubmit && !submitting ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
