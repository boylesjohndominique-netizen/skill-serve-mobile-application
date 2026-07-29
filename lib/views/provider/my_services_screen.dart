import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../data/mock/mock_data.dart';

/// Provider's own service listings — add, edit, pause/activate.
class MyServicesScreen extends StatelessWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = MockData.services.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        actions: [
          IconButton(onPressed: () => context.push('/add-service'), icon: const Icon(Icons.add_rounded)),
        ],
      ),
      body: SafeArea(
        child: services.isEmpty
            ? EmptyState(
                icon: Icons.design_services_outlined,
                title: 'No services yet',
                message: 'Add your first service so clients can find and book you.',
                actionLabel: 'Add a service',
                onAction: () => context.push('/add-service'),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSizes.pageHPad),
                itemCount: services.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                itemBuilder: (context, i) {
                  final s = services[i];
                  return InkWell(
                    onTap: () => context.push('/edit-service/${s.id}'),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    child: Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            child: CachedNetworkImage(imageUrl: s.coverImage, width: 60, height: 60, fit: BoxFit.cover, placeholder: (c, u) => const ShimmerPlaceholder(width: 60, height: 60)),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.title, style: AppTextStyles.titleMedium, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text('${Formatters.peso(s.price)} • ${s.duration}', style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          StatusBadge.fromStatus(s.status),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
