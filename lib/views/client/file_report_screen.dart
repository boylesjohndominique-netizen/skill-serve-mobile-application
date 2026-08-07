import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/report_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/inputs/app_text_field.dart';
import '../../data/mock/mock_data.dart';
import '../../models/report_model.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

/// File a complaint / dispute — reason picklist + details + optional booking.
class FileReportScreen extends StatefulWidget {
  final String? bookingId;
  const FileReportScreen({super.key, this.bookingId});

  @override
  State<FileReportScreen> createState() => _FileReportScreenState();
}

class _FileReportScreenState extends State<FileReportScreen> {
  final _detailsController = TextEditingController();
  final _reportedController = TextEditingController();
  String? _reason;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Report an Issue')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What happened?', style: AppTextStyles.displayMedium)
                  .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: 6),
              Text(
                'Reports are reviewed by our support team. Please share as much detail as you can.',
                style: AppTextStyles.bodyLarge,
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.xl),

              if (widget.bookingId != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Row(
                    children: [
                      const AppIcon(AppIcons.link_rounded, size: 16, color: AppColors.info),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          'Linked to booking ${widget.bookingId}',
                          style: AppTextStyles.label.copyWith(color: AppColors.info, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
                const SizedBox(height: AppSizes.lg),
              ],

              Text('Who are you reporting?', style: AppTextStyles.titleLarge)
                  .animate().fadeIn(delay: 180.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.sm),
              AppTextField(
                label: 'Provider name',
                hint: 'Full name of the provider',
                controller: _reportedController,
                prefixIcon: AppIcons.person_outline_rounded,
              ).animate().fadeIn(delay: 220.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.xl),

              Text('Reason', style: AppTextStyles.titleLarge)
                  .animate().fadeIn(delay: 260.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.sm),
              for (var i = 0; i < MockData.reportReasons.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: _ReasonTile(
                    label: MockData.reportReasons[i],
                    selected: _reason == MockData.reportReasons[i],
                    onTap: () => setState(() => _reason = MockData.reportReasons[i]),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 300 + i * 45), duration: 300.ms)
                      .slideX(begin: 0.05, end: 0),
                ),
              const SizedBox(height: AppSizes.xl),

              Text('Details', style: AppTextStyles.titleLarge)
                  .animate().fadeIn(delay: 600.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.sm),
              AppTextField(
                label: 'Tell us more',
                hint: 'Describe what happened, when, and any supporting facts…',
                controller: _detailsController,
                maxLines: 5,
              ).animate().fadeIn(delay: 640.ms, duration: 350.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: AppSizes.xxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: PrimaryButton(
            label: 'Submit report',
            icon: AppIcons.flag_rounded,
            isLoading: controller.isSubmitting,
            onPressed: _reason == null || _detailsController.text.trim().isEmpty
                ? null
                : () async {
                    if (_reason == null || _detailsController.text.trim().isEmpty) {
                      AppSnackbar.error(context, 'Please pick a reason and add details.');
                      return;
                    }
                    final report = await context.read<ReportController>().fileReport(
                          reportedName: _reportedController.text.trim().isEmpty
                              ? 'Unknown provider'
                              : _reportedController.text.trim(),
                          reason: _reason!,
                          details: _detailsController.text.trim(),
                        );
                    if (!context.mounted || report == null) return;
                    _showConfirmation(context, report);
                  },
          ),
        ),
      ),
    );
  }

  void _showConfirmation(BuildContext context, ReportModel report) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
              child: const AppIcon(AppIcons.check_rounded, color: AppColors.success, size: 32),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: AppSizes.lg),
            Text('Report submitted', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Your report ${report.id} is now under review. Our team typically responds within 3–5 business days.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSizes.xl),
            PrimaryButton(label: 'Track my reports', onPressed: () {
              Navigator.of(context).pop();
              context.pushReplacement('/my-reports');
            }),
            const SizedBox(height: AppSizes.sm),
            OutlinedAppButton(label: 'Back', onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            }),
          ],
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary.withValues(alpha: 0.07) : (isDark ? AppColors.surfaceDark : AppColors.surface),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: selected ? AppColors.secondary : (isDark ? AppColors.lineDark : AppColors.line),
            width: selected ? 1.4 : 0.8,
          ),
        ),
        child: Row(
          children: [
            AppIcon(
              selected ? AppIcons.radio_button_checked_rounded : AppIcons.radio_button_off_rounded,
              size: 18,
              color: selected ? AppColors.secondary : AppColors.neutral300,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
          ],
        ),
      ),
    );
  }
}
