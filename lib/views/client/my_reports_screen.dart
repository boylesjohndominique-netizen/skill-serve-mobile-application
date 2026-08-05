import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/report_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../models/report_model.dart';

/// My reports — status pills plus a timeline of admin actions per report.
class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportController>().loadMyReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        actions: [
          IconButton(onPressed: () => context.push('/file-report'), icon: const Icon(Icons.add_rounded)),
        ],
      ),
      body: SafeArea(
        child: controller.isLoading
            ? const Padding(padding: EdgeInsets.all(AppSizes.pageHPad), child: ShimmerCardList(itemHeight: 120))
            : controller.reports.isEmpty
                ? EmptyState(
                    icon: Icons.flag_outlined,
                    title: 'No reports yet',
                    message: 'If something went wrong with a booking, you can file a report here.',
                    actionLabel: 'File a report',
                    onAction: () => context.push('/file-report'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.pageHPad),
                    itemCount: controller.reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                    itemBuilder: (context, i) => _ReportCard(report: controller.reports[i], isDark: isDark)
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                        .slideY(begin: 0.06, end: 0),
                  ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final bool isDark;

  const _ReportCard({required this.report, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: surfaceColor,
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
                child: Text(report.reason, style: AppTextStyles.titleMedium, overflow: TextOverflow.ellipsis),
              ),
              StatusBadge.fromStatus(report.status.name),
            ],
          ),
          const SizedBox(height: 2),
          Text('vs ${report.reportedName}', style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSizes.sm),
          Text(report.details, style: AppTextStyles.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Text('#${report.id}', style: AppTextStyles.monoSm.copyWith(color: AppColors.neutral300)),
              const Spacer(),
              Text(Formatters.relative(report.createdAt), style: AppTextStyles.bodySmall),
            ],
          ),
          if (report.updates.isNotEmpty) ...[
            Divider(height: AppSizes.xl, color: lineColor),
            for (var u in report.updates.reversed.take(3))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(_iconFor(u.status), size: 13, color: _colorFor(u.status)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(u.label, style: AppTextStyles.bodySmall)),
                    Text(Formatters.relative(u.at), style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(String status) {
    switch (status) {
      case 'investigating':
        return Icons.manage_search_rounded;
      case 'warned':
        return Icons.warning_amber_rounded;
      case 'suspended':
        return Icons.block_rounded;
      case 'closed':
        return Icons.task_alt_rounded;
      default:
        return Icons.flag_outlined;
    }
  }

  Color _colorFor(String status) {
    switch (status) {
      case 'investigating':
        return AppColors.info;
      case 'warned':
        return AppColors.warning;
      case 'suspended':
        return AppColors.error;
      case 'closed':
        return AppColors.success;
      default:
        return AppColors.neutral300;
    }
  }
}
