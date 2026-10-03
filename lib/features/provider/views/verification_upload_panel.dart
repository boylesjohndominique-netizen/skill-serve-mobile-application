import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/buttons/outlined_app_button.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../controllers/verification_controller.dart';
import '../models/verification_document_model.dart';
import '../../../core/theme/app_palette.dart';

/// Pick verification documents (camera, gallery or PDF), label each one and
/// send them for review. Used by the Verification screen and onboarding.
///
/// Reads the nearest [VerificationController]; calls [onSubmitted] after the
/// API accepted the documents.
class VerificationUploadPanel extends StatefulWidget {
  final VoidCallback? onSubmitted;
  final String submitLabel;

  const VerificationUploadPanel({super.key, this.onSubmitted, this.submitLabel = 'Submit for review'});

  @override
  State<VerificationUploadPanel> createState() => _VerificationUploadPanelState();
}

class _VerificationUploadPanelState extends State<VerificationUploadPanel> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addDocument() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add a document', style: AppTextStyles.titleLarge),
              const SizedBox(height: 4),
              Text('A clear photo or a PDF, up to 10 MB.', style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSizes.md),
              for (final (value, label, icon) in const [
                ('camera', 'Take a photo', AppIcons.camera_alt_rounded),
                ('gallery', 'Choose a photo', AppIcons.photo_library_outlined),
                ('pdf', 'Choose a PDF', AppIcons.description_outlined),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: AppIcon(icon, color: context.accentInk),
                  title: Text(label, style: AppTextStyles.bodyLarge),
                  onTap: () => Navigator.of(context).pop(value),
                ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    PendingVerificationDocument? document;
    try {
      document = source == 'pdf' ? await _pickPdf() : await _pickPhoto(source == 'camera');
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'That file could not be opened. Try another one.');
      return;
    }
    if (document == null || !mounted) return;

    final error = context.read<VerificationController>().add(document);
    if (error != null) AppSnackbar.error(context, error);
  }

  Future<PendingVerificationDocument?> _pickPhoto(bool camera) async {
    final file = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2400,
    );
    if (file == null) return null;
    final name = file.name.contains('.') ? file.name : '${file.name}.jpg';
    return PendingVerificationDocument(type: _defaultType(), fileName: name, bytes: await file.readAsBytes());
  }

  Future<PendingVerificationDocument?> _pickPdf() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['pdf']);
    if (file == null) return null;
    return PendingVerificationDocument(type: _defaultType(), fileName: file.name, bytes: await file.readAsBytes());
  }

  /// The first document is usually the ID; later ones default to certificates.
  String _defaultType() =>
      context.read<VerificationController>().picked.isEmpty ? 'government_id' : 'certificate';

  Future<void> _submit() async {
    final controller = context.read<VerificationController>();
    final ok = await controller.submit(notes: _notesController.text);
    if (!mounted) return;
    if (ok) {
      _notesController.clear();
      AppSnackbar.success(context, 'Documents sent. We will notify you when they are reviewed.');
      widget.onSubmitted?.call();
    } else {
      AppSnackbar.error(context, controller.errorMessage ?? 'Unable to submit your documents.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VerificationController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < controller.picked.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: AppSizes.sm),
            padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.xs, AppSizes.sm),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5), width: 0.8),
            ),
            child: Row(
              children: [
                AppIcon(
                  controller.picked[i].isPdf ? AppIcons.description_outlined : AppIcons.photo_library_outlined,
                  size: 20,
                  color: AppColors.secondaryDeep,
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(controller.picked[i].fileName,
                          style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      DropdownButton<String>(
                        value: controller.picked[i].type,
                        isExpanded: true,
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        style: AppTextStyles.bodySmall,
                        items: [
                          for (final (code, label) in VerificationDocumentModel.types)
                            DropdownMenuItem(value: code, child: Text(label)),
                        ],
                        onChanged: controller.isSubmitting ? null : (type) => controller.setType(i, type!),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  onPressed: controller.isSubmitting ? null : () => controller.remove(i),
                  icon: const AppIcon(AppIcons.close_rounded, size: 18),
                ),
              ],
            ),
          ),
        OutlinedAppButton(
          label: controller.picked.isEmpty ? 'Add a document' : 'Add another document',
          icon: AppIcons.upload_file_rounded,
          onPressed: controller.isSubmitting || !controller.canAddMore ? null : _addDocument,
        ),
        if (controller.picked.isNotEmpty) ...[
          const SizedBox(height: AppSizes.md),
          AppTextField(
            label: 'Message to the reviewer (optional)',
            hint: 'e.g. My TESDA certificate is attached',
            controller: _notesController,
            maxLines: 3,
            maxLength: 1000,
            enabled: !controller.isSubmitting,
          ),
          const SizedBox(height: AppSizes.sm),
          if (controller.isSubmitting) ...[
            LinearProgressIndicator(value: controller.progress > 0 ? controller.progress : null),
            const SizedBox(height: AppSizes.sm),
          ],
          PrimaryButton(
            label: widget.submitLabel,
            icon: AppIcons.check_circle_rounded,
            isLoading: controller.isSubmitting,
            onPressed: controller.isSubmitting ? null : _submit,
          ),
        ],
      ],
    );
  }
}
