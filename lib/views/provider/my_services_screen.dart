import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../data/mock/mock_data.dart';
import '../../models/service_model.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

/// Provider's own service listings — add, edit, and toggle active/hidden.
class MyServicesScreen extends StatefulWidget {
  final bool embedded;
  const MyServicesScreen({super.key, this.embedded = false});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  late List<ServiceModel> _services;

  @override
  void initState() {
    super.initState();
    _services = [...MockData.services.take(5)];
  }

  void _toggle(ServiceModel service, bool visible) {
    setState(() {
      final index = _services.indexWhere((s) => s.id == service.id);
      if (index != -1) {
        _services[index] = ServiceModel(
          id: service.id,
          providerId: service.providerId,
          categoryId: service.categoryId,
          title: service.title,
          description: service.description,
          price: service.price,
          duration: service.duration,
          status: visible ? 'active' : 'hidden',
          coverImage: service.coverImage,
        );
      }
    });
    AppSnackbar.success(context, visible ? 'Service is now visible to clients.' : 'Service hidden from clients.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    final header = widget.embedded
        ? Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.pageHPad, AppSizes.lg, AppSizes.pageHPad, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Services', style: AppTextStyles.displayMedium)
                    .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
                IconButton(
                  onPressed: () => context.push('/add-service'),
                  icon: const AppIcon(AppIcons.add_circle_rounded, color: AppColors.secondary, size: 26),
                ),
              ],
            ),
          )
        : null;

    final list = _services.isEmpty
        ? EmptyState(
            icon: AppIcons.design_services_outlined,
            title: 'No services yet',
            message: 'Add your first service so clients can find and book you.',
            actionLabel: 'Add a service',
            onAction: () => context.push('/add-service'),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(AppSizes.pageHPad),
            itemCount: _services.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
            itemBuilder: (context, i) {
              final s = _services[i];
              return _ServiceCard(
                service: s,
                onTap: () => context.push('/edit-service/${s.id}'),
                onToggle: (v) => _toggle(s, v),
                isDark: isDark,
                surfaceColor: surfaceColor,
                lineColor: lineColor,
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                  .slideX(begin: 0.05, end: 0);
            },
          );

    if (widget.embedded) {
      return Scaffold(body: SafeArea(child: Column(children: [header ?? const SizedBox(), Expanded(child: list)])));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        actions: [IconButton(onPressed: () => context.push('/add-service'), icon: const AppIcon(AppIcons.add_rounded))],
      ),
      body: SafeArea(child: list),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;
  final void Function(bool) onToggle;
  final bool isDark;
  final Color surfaceColor;
  final Color lineColor;

  const _ServiceCard({
    required this.service,
    required this.onTap,
    required this.onToggle,
    required this.isDark,
    required this.surfaceColor,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.md,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: service.status == 'hidden' ? surfaceColor.withValues(alpha: 0.6) : surfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
          boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              child: CachedNetworkImage(
                imageUrl: service.coverImage,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (c, u) => const ShimmerPlaceholder(width: 60, height: 60),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: service.status == 'hidden' ? AppColors.neutral300 : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text('${Formatters.peso(service.price)} • ${service.duration}', style: AppTextStyles.monoSm.copyWith(color: AppColors.neutral300)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusBadge.fromStatus(service.status),
                      const SizedBox(width: AppSizes.sm),
                      Flexible(
                        child: Text(
                          service.status == 'hidden' ? 'Hidden' : 'Visible to clients',
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: service.status == 'active',
                  onChanged: onToggle,
                  activeTrackColor: AppColors.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
