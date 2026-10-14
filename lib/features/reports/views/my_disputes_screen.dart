import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';
import '../controllers/report_controller.dart';
import '../models/report_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/app_icon.dart';
import 'case_card.dart';
import 'raise_dispute_flow.dart';

/// The booking disputes this account is a party to — raised by either side
/// from a booking. Each card opens its booking, and takes more photos as
/// proof while the case is open.
class MyDisputesScreen extends StatefulWidget {
  const MyDisputesScreen({super.key});

  @override
  State<MyDisputesScreen> createState() => _MyDisputesScreenState();
}

class _MyDisputesScreenState extends State<MyDisputesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportController>().loadDisputes();
    });
  }

  Future<void> _reload() => context.read<ReportController>().loadDisputes();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportController>();
    final disputes = controller.disputes;
    final error = controller.disputesError;
    // `provider_name` is the provider on the booking — the provider's own
    // name when they are the one looking.
    final isProvider = context.watch<AuthController>().isProvider;

    return Scaffold(
      appBar: AppBar(title: const Text('My Disputes')),
      body: SafeArea(
        child: controller.isLoadingDisputes
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pageHPad),
                child: ShimmerCardList(itemHeight: 110),
              )
            : error != null
                ? ErrorState(message: error, onRetry: _reload)
                : RefreshIndicator(
                    onRefresh: _reload,
                    child: disputes.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.only(top: AppSizes.xxl),
                            children: const [
                              EmptyState(
                                icon: AppIcons.gavel_rounded,
                                title: 'No disputes raised',
                                message:
                                    'If a booking goes wrong, you can raise a dispute from the booking and track it here.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSizes.pageHPad),
                            itemCount: disputes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                            itemBuilder: (context, i) => CaseCard(
                              title: disputes[i].serviceTitle.isEmpty
                                  ? 'Booking ${disputes[i].bookingId}'
                                  : disputes[i].serviceTitle,
                              subtitle: isProvider || disputes[i].providerName.isEmpty
                                  ? null
                                  : 'With ${disputes[i].providerName}',
                              status: disputes[i].disputeStatus,
                              body: disputes[i].reason,
                              outcome: disputes[i].resolution,
                              openedAt: disputes[i].disputedAt,
                              decidedAt: disputes[i].closedAt,
                              reference: disputes[i].bookingNumber,
                              onTap: () => context.push('/booking-details/${disputes[i].bookingId}'),
                              footer: _EvidenceStrip(dispute: disputes[i]),
                            )
                                .animate()
                                .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                                .slideY(begin: 0.06, end: 0),
                          ),
                  ),
      ),
      floatingActionButton: error != null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _raiseDispute(context),
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.primary,
              icon: const AppIcon(AppIcons.gavel_rounded, size: 18, color: AppColors.primary),
              label: const Text('Raise a dispute'),
            ),
    );
  }

  /// Pick the booking that went wrong, then describe it — the same sheet as
  /// on the booking itself. The new dispute appears at the top of this list.
  Future<void> _raiseDispute(BuildContext context) async {
    final booking = await pickDisputableBooking(context);
    if (booking == null || !context.mounted) return;
    await raiseDisputeFlow(context, booking.id);
  }
}

/// What each side has attached to a dispute, and — while the case is open — a
/// way to add a photo. The photos themselves are only opened by the
/// administrators reviewing the case.
class _EvidenceStrip extends StatelessWidget {
  final DisputeModel dispute;
  const _EvidenceStrip({required this.dispute});

  Future<void> _addPhoto(BuildContext context) async {
    final reports = context.read<ReportController>();
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2400,
    );
    if (picked == null || !context.mounted) return;

    final caption = await AppDialog.prompt(
      context,
      title: 'Describe this photo',
      message: 'A short note helps our team understand what it shows.',
      fieldLabel: 'Caption (optional)',
      hint: 'e.g. Water still leaking after the repair',
      confirmLabel: 'Upload',
      maxLength: 500,
    );
    if (caption == null || !context.mounted) return;

    final ok = await reports.addDisputeEvidence(
      bookingId: dispute.bookingId,
      filePath: picked.path,
      caption: caption,
    );
    if (!context.mounted) return;
    if (ok) {
      AppSnackbar.success(context, 'Photo added to the dispute.');
    } else {
      AppSnackbar.error(context, reports.errorMessage ?? 'Unable to upload this photo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = context.watch<ReportController>().isSubmitting;
    final count = dispute.evidence.length;
    final mine = dispute.evidence.where((e) => e.isMine).length;

    if (count == 0 && !dispute.canAddEvidence) return const SizedBox.shrink();

    return Row(
      children: [
        const AppIcon(AppIcons.photo_library_outlined, size: 16, color: AppColors.neutral400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            count == 0
                ? 'No photos attached yet'
                : '$count ${count == 1 ? 'photo' : 'photos'} attached'
                    '${mine > 0 && mine < count ? ' ($mine from you)' : ''}',
            style: AppTextStyles.bodySmall,
          ),
        ),
        if (dispute.canAddEvidence)
          TextButton(
            onPressed: submitting ? null : () => _addPhoto(context),
            child: Text(submitting ? 'Uploading…' : 'Add photo',
                style: AppTextStyles.label.copyWith(color: context.accentInk)),
          ),
      ],
    );
  }
}
