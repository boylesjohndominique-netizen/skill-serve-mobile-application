import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/inputs/app_text_field.dart';
import '../../services/portfolio_service.dart';

/// Upload form for a new portfolio item. Image selection is wired to
/// image_picker for a real UI experience; the actual multipart upload is
/// left as a placeholder in [PortfolioService.uploadPortfolioItem].
class UploadPortfolioScreen extends StatefulWidget {
  const UploadPortfolioScreen({super.key});

  @override
  State<UploadPortfolioScreen> createState() => _UploadPortfolioScreenState();
}

class _UploadPortfolioScreenState extends State<UploadPortfolioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _portfolioService = PortfolioService();
  XFile? _pickedImage;
  bool _submitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _pickedImage = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImage == null) {
      AppSnackbar.error(context, 'Please select an image first.');
      return;
    }
    setState(() => _submitting = true);
    await _portfolioService.uploadPortfolioItem(
      title: _title.text.trim(),
      description: _description.text.trim(),
      imagePath: _pickedImage!.path,
    );
    setState(() => _submitting = false);
    if (mounted) {
      AppSnackbar.success(context, 'Submitted for admin review.');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Portfolio')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      border: Border.all(color: AppColors.line, style: BorderStyle.solid),
                    ),
                    child: _pickedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.neutral300),
                              const SizedBox(height: 8),
                              Text('Tap to select a photo', style: AppTextStyles.bodyMedium),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                            child: Image.file(File(_pickedImage!.path), fit: BoxFit.cover, width: double.infinity, height: 200),
                          ),
                  ),
                ),
                const SizedBox(height: AppSizes.xl),
                AppTextField(label: 'Title', hint: 'e.g. Bathroom Repipe Job', controller: _title, validator: Validators.required),
                const SizedBox(height: AppSizes.lg),
                AppTextField(
                  label: 'Description',
                  hint: 'Briefly describe the work shown…',
                  controller: _description,
                  maxLines: 4,
                  validator: Validators.required,
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Submissions are reviewed by an admin before appearing on your public profile.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSizes.xxl),
                PrimaryButton(label: 'Submit for review', isLoading: _submitting, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
