import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/portfolio_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/feedback/app_dialog.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../data/mock/mock_data.dart';

/// Provider's own portfolio grid — shows moderation status per item and
/// links to Upload Portfolio for new submissions.
class ProviderPortfolioScreen extends StatefulWidget {
  final bool embedded;
  const ProviderPortfolioScreen({super.key, this.embedded = false});

  @override
  State<ProviderPortfolioScreen> createState() => _ProviderPortfolioScreenState();
}

class _ProviderPortfolioScreenState extends State<ProviderPortfolioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortfolioController>().load(MockData.currentProvider.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PortfolioController>();

    final body = SafeArea(
      child: controller.isLoading
          ? const Padding(padding: EdgeInsets.all(AppSizes.pageHPad), child: ShimmerCardList(itemHeight: 160))
          : controller.items.isEmpty
              ? EmptyState(
                  icon: Icons.photo_library_outlined,
                  title: 'Showcase your work',
                  message: 'Upload photos of completed jobs to build trust with future clients.',
                  actionLabel: 'Upload portfolio item',
                  onAction: () => context.push('/upload-portfolio'),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSizes.pageHPad),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSizes.sm,
                    crossAxisSpacing: AppSizes.sm,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: controller.items.length,
                  itemBuilder: (context, i) {
                    final item = controller.items[i];
                    return GestureDetector(
                      onTap: item.status == 'rejected'
                          ? () async {
                              final confirmed = await AppDialog.confirm(
                                context,
                                title: 'Resubmit this item?',
                                message: 'It will go back into review. You can edit it first from your gallery.',
                                confirmLabel: 'Resubmit',
                              );
                              if (confirmed && context.mounted) {
                                await controller.resubmit(item.id);
                                if (context.mounted) AppSnackbar.success(context, 'Item resubmitted for review.');
                              }
                            }
                          : null,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(imageUrl: item.image, fit: BoxFit.cover, placeholder: (c, u) => const ShimmerPlaceholder()),
                            if (item.status == 'rejected')
                              Container(
                                color: AppColors.error.withValues(alpha: 0.25),
                              ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: StatusBadge.fromStatus(item.status),
                            ),
                            if (item.status == 'rejected')
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 28,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.rotate_left_rounded, size: 12, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Tap to resubmit', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.transparent, Colors.black54],
                                  ),
                                ),
                                child: Text(
                                  item.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                        .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOutBack);
                  },
                ),
    );

    if (widget.embedded) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Portfolio'),
          automaticallyImplyLeading: false,
          actions: [IconButton(onPressed: () => context.push('/upload-portfolio'), icon: const Icon(Icons.add_rounded))],
        ),
        body: body,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [IconButton(onPressed: () => context.push('/upload-portfolio'), icon: const Icon(Icons.add_rounded))],
      ),
      body: body,
    );
  }
}
