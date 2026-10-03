import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../controllers/report_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/status_badge.dart';
import '../models/report_model.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// Everything the account has escalated: complaints about people, and disputes
/// about jobs. They are separate cases with separate lifecycles, so the screen
/// keeps them in separate tabs.
class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportController>().loadMyReports();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reload() => context.read<ReportController>().loadMyReports();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportController>();
    final failed = controller.loadFailed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        bottom: failed
            ? null
            : TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Reports (${controller.reports.length})'),
                  Tab(text: 'Disputes (${controller.disputes.length})'),
                ],
              ),
      ),
      body: SafeArea(
        child: controller.isLoading
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pageHPad),
                child: ShimmerCardList(itemHeight: 110),
              )
            : failed
                ? ErrorState(message: controller.errorMessage!, onRetry: _reload)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _ReportList(
                        reports: controller.reports,
                        error: controller.reportsError,
                        onRefresh: _reload,
                      ),
                      _DisputeList(
                        disputes: controller.disputes,
                        error: controller.disputesError,
                        onRefresh: _reload,
                      ),
                    ],
                  ),
      ),
      floatingActionButton: failed
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/file-report'),
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.primary,
              icon: const AppIcon(AppIcons.flag_outlined, size: 18, color: AppColors.primary),
              label: const Text('Report an issue'),
            ),
    );
  }
}

class _ReportList extends StatelessWidget {
  final List<ReportModel> reports;
  final String? error;
  final Future<void> Function() onRefresh;

  const _ReportList({required this.reports, required this.error, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (error != null) return ErrorState(message: error!, onRetry: onRefresh);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: reports.isEmpty
          ? ListView(
              padding: const EdgeInsets.only(top: AppSizes.xxl),
              children: const [
                EmptyState(
                  icon: AppIcons.flag_outlined,
                  title: 'No reports filed',
                  message: 'Complaints you raise about a customer or provider will appear here.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.pageHPad),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
              itemBuilder: (context, i) => _CaseCard(
                title: reports[i].reasonLabel,
                subtitle: reports[i].subjectLabel,
                status: reports[i].status.name,
                // For a review or message, show what was reported first.
                body: reports[i].excerpt == null || reports[i].excerpt!.isEmpty
                    ? reports[i].details
                    : '“${reports[i].excerpt}”\n\n${reports[i].details}',
                outcome: reports[i].outcome,
                openedAt: reports[i].createdAt,
                decidedAt: reports[i].decidedAt,
                reference: '#${reports[i].id}',
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                  .slideY(begin: 0.06, end: 0),
            ),
    );
  }
}

class _DisputeList extends StatelessWidget {
  final List<DisputeModel> disputes;
  final String? error;
  final Future<void> Function() onRefresh;

  const _DisputeList({required this.disputes, required this.error, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (error != null) return ErrorState(message: error!, onRetry: onRefresh);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: disputes.isEmpty
          ? ListView(
              padding: const EdgeInsets.only(top: AppSizes.xxl),
              children: const [
                EmptyState(
                  icon: AppIcons.gavel_rounded,
                  title: 'No disputes raised',
                  message:
                      'If a job goes wrong, you can raise a dispute from the booking and track it here.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.pageHPad),
              itemCount: disputes.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
              itemBuilder: (context, i) => _CaseCard(
                title: disputes[i].serviceTitle.isEmpty
                    ? 'Booking ${disputes[i].bookingId}'
                    : disputes[i].serviceTitle,
                subtitle: disputes[i].providerName.isEmpty
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
    );
  }
}

/// One escalated case — shared by reports and disputes, which carry the same
/// shape: what it is about, where it got to, and what support decided.
class _CaseCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String status;
  final String body;
  final String? outcome;
  final DateTime? openedAt;
  final DateTime? decidedAt;
  final String reference;
  final VoidCallback? onTap;

  /// Extra content under the body — the dispute evidence strip.
  final Widget? footer;

  const _CaseCard({
    required this.title,
    required this.status,
    required this.body,
    required this.reference,
    this.subtitle,
    this.outcome,
    this.openedAt,
    this.decidedAt,
    this.onTap,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
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
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: AppSizes.sm),
                StatusBadge.fromStatus(status),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: AppTextStyles.bodySmall),
            ],
            const SizedBox(height: AppSizes.sm),
            Text(body, style: AppTextStyles.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
            if (outcome != null && outcome!.isNotEmpty) ...[
              const SizedBox(height: AppSizes.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Support response',
                        style: AppTextStyles.label.copyWith(color: AppColors.neutral400)),
                    const SizedBox(height: 2),
                    Text(outcome!, style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            ],
            if (footer != null) ...[
              const SizedBox(height: AppSizes.md),
              footer!,
            ],
            Divider(height: AppSizes.lg, color: lineColor),
            Row(
              children: [
                if (reference.isNotEmpty)
                  Text(reference, style: AppTextStyles.monoSm),
                const Spacer(),
                Text(
                  decidedAt != null
                      ? 'Updated ${Formatters.relative(decidedAt!)}'
                      : openedAt != null
                          ? 'Filed ${Formatters.relative(openedAt!)}'
                          : '',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
