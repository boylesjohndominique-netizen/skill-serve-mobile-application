import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/report_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/private_photo_strip.dart';
import '../../../core/constants/app_icons.dart';
import 'case_card.dart';

/// The complaints this account has filed about people, reviews, messages or
/// services. Booking disputes are a separate case with their own lifecycle,
/// and live on My Disputes.
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
      context.read<ReportController>().loadReports();
    });
  }

  Future<void> _reload() => context.read<ReportController>().loadReports();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportController>();
    final reports = controller.reports;
    final error = controller.reportsError;

    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: SafeArea(
        child: controller.isLoadingReports
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pageHPad),
                child: ShimmerCardList(itemHeight: 110),
              )
            : error != null
                ? ErrorState(message: error, onRetry: _reload)
                : RefreshIndicator(
                    onRefresh: _reload,
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
                            itemBuilder: (context, i) => CaseCard(
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
                              footer: reports[i].photoUrls.isEmpty
                                  ? null
                                  : PrivatePhotoStrip(urls: reports[i].photoUrls, size: 56),
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
              onPressed: () => context.push('/file-report'),
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.primary,
              icon: const AppIcon(AppIcons.flag_outlined, size: 18, color: AppColors.primary),
              label: const Text('Report an issue'),
            ),
    );
  }
}
