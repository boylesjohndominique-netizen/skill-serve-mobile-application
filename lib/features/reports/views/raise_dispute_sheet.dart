import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_bottom_sheet.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/inputs/photo_attachments_field.dart';

/// What the user wants to dispute: what went wrong, and photos as proof.
typedef DisputeDraft = ({String reason, List<String> photoPaths});

/// Asks what went wrong with a booking and lets the user attach photos as
/// proof (up to [maxPhotos], the API's limit per dispute). Null when they
/// back out.
Future<DisputeDraft?> showRaiseDisputeSheet(BuildContext context, {int maxPhotos = 5}) {
  return AppBottomSheet.show<DisputeDraft>(context, child: _RaiseDisputeForm(maxPhotos: maxPhotos));
}

class _RaiseDisputeForm extends StatefulWidget {
  final int maxPhotos;
  const _RaiseDisputeForm({required this.maxPhotos});

  @override
  State<_RaiseDisputeForm> createState() => _RaiseDisputeFormState();
}

class _RaiseDisputeFormState extends State<_RaiseDisputeForm> {
  final _reason = TextEditingController();
  List<String> _photos = const [];

  /// The API needs at least 10 characters to act on a dispute.
  static const _minLength = 10;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  bool get _canSubmit => _reason.text.trim().length >= _minLength;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Raise a dispute?', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Our support team will review this booking and contact both of you. Tell us what went wrong.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSizes.lg),
            AppTextField(
              label: 'What went wrong?',
              hint: 'Describe the problem in at least $_minLength characters',
              controller: _reason,
              maxLines: 4,
              maxLength: 2000,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSizes.md),
            Text('Photos as proof', style: AppTextStyles.titleMedium),
            const SizedBox(height: 4),
            PhotoAttachmentsField(
              paths: _photos,
              max: widget.maxPhotos,
              helper: 'Optional · the work, damage or receipts · up to ${widget.maxPhotos}',
              onChanged: (photos) => setState(() => _photos = photos),
            ),
            const SizedBox(height: AppSizes.xl),
            PrimaryButton(
              label: 'Raise dispute',
              icon: AppIcons.gavel_rounded,
              onPressed: _canSubmit
                  ? () => Navigator.of(context).pop<DisputeDraft>((reason: _reason.text.trim(), photoPaths: _photos))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
