import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/status_badge.dart';
import '../controllers/provider_services_controller.dart';
import '../models/provider_service_model.dart';

/// Provider's own service listings with their approval state.
class MyServicesScreen extends StatefulWidget {
  final bool embedded;
  const MyServicesScreen({super.key, this.embedded = false});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ProviderServicesController>().load());
  }

  Future<void> _openAndRefresh(String location) async {
    await context.push(location);
    if (mounted) await context.read<ProviderServicesController>().load();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderServicesController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget body;
    if (controller.isLoading && controller.services.isEmpty) {
      body = const LoadingState();
    } else if (controller.errorMessage != null && controller.services.isEmpty) {
      body = ErrorState(message: controller.errorMessage!, onRetry: controller.load);
    } else if (controller.services.isEmpty) {
      body = EmptyState(
        icon: AppIcons.design_services_outlined,
        title: 'No services yet',
        message: 'Add your first service. It goes live for customers once an administrator approves it.',
        actionLabel: 'Add a service',
        onAction: () => _openAndRefresh('/add-service'),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: controller.load,
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          itemCount: controller.services.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
          itemBuilder: (context, i) {
            final service = controller.services[i];
            return _ServiceCard(
              service: service,
              isDark: isDark,
              onTap: () => _openAndRefresh('/edit-service/${service.id}'),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                .slideX(begin: 0.05, end: 0);
          },
        ),
      );
    }

    if (widget.embedded) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.pageHPad, AppSizes.lg, AppSizes.pageHPad, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Services', style: AppTextStyles.displayMedium)
                        .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
                    IconButton(
                      tooltip: 'Add service',
                      onPressed: () => _openAndRefresh('/add-service'),
                      icon: const AppIcon(AppIcons.add_circle_rounded, color: AppColors.secondary, size: 26),
                    ),
                  ],
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        actions: [
          IconButton(
            tooltip: 'Add service',
            onPressed: () => _openAndRefresh('/add-service'),
            icon: const AppIcon(AppIcons.add_rounded),
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ProviderServiceModel service;
  final bool isDark;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.isDark, required this.onTap});

  StatusBadge get _approvalBadge => switch (service.approvalStatus) {
        'approved' => const StatusBadge(label: 'Approved', tone: StatusTone.success, icon: AppIcons.verified_rounded),
        'rejected' => StatusBadge.fromStatus('rejected'),
        _ => const StatusBadge(label: 'Pending review', tone: StatusTone.warning, icon: AppIcons.hourglass_top_rounded),
      };

  String get _visibilityLabel {
    if (service.isLive) return 'Visible to customers';
    if (service.isHidden) return 'Hidden by an administrator';
    if (service.isRejected) return 'Edit and resubmit';
    return 'Waiting for administrator approval';
  }

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;
    final priceSuffix = switch (service.priceType) { 'hourly' => ' / hr', 'custom' => ' (custom)', _ => '' };
    final details = [
      '${Formatters.peso(service.price)}$priceSuffix',
      if (service.duration.isNotEmpty) service.duration,
      if (service.categoryName.isNotEmpty) service.categoryName,
    ].join(' • ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: service.isLive ? surfaceColor : surfaceColor.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
          boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.secondarySoft,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              alignment: Alignment.center,
              child: const AppIcon(AppIcons.design_services_rounded, color: AppColors.secondaryDeep, size: 22),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.title, style: AppTextStyles.titleMedium, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(details, style: AppTextStyles.monoSm.copyWith(color: AppColors.neutral300), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _approvalBadge,
                      if (service.isHidden) StatusBadge.fromStatus('hidden'),
                      Text(_visibilityLabel, style: AppTextStyles.bodySmall),
                    ],
                  ),
                  if (service.isRejected && (service.rejectionReason ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Reason: ${service.rejectionReason}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const AppIcon(AppIcons.chevron_right_rounded, color: AppColors.neutral300, size: 20),
          ],
        ),
      ),
    );
  }
}
