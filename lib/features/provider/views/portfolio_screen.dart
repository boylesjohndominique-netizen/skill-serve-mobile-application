import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../provider/controllers/portfolio_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// The provider's own portfolio grid: work samples they have published,
/// with a long-press to remove one and a link to upload more.
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
      if (context.read<AuthController>().currentUser != null) {
        context.read<PortfolioController>().loadMine();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PortfolioController>();

    final body = SafeArea(
      child: controller.isLoading
          ? const Padding(padding: EdgeInsets.all(AppSizes.pageHPad), child: ShimmerCardList(itemHeight: 160))
          : (controller.errorMessage != null && controller.items.isEmpty)
              ? ErrorState(
                  message: controller.errorMessage!,
                  onRetry: controller.loadMine,
                )
          : controller.items.isEmpty
              ? EmptyState(
                  icon: AppIcons.photo_library_outlined,
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
                      onLongPress: () async {
                        final confirmed = await AppDialog.confirm(
                          context,
                          title: 'Remove this item?',
                          message:
                              'It will be deleted from your public profile. This cannot be undone.',
                          confirmLabel: 'Remove',
                        );
                        if (!confirmed || !context.mounted) return;
                        final removed = await controller.remove(item.id);
                        if (!context.mounted) return;
                        if (removed) {
                          AppSnackbar.success(context, 'Item removed.');
                        } else {
                          AppSnackbar.error(
                              context,
                              controller.errorMessage ??
                                  'We could not remove that item.');
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: item.image,
                              fit: BoxFit.cover,
                              placeholder: (c, u) => const ShimmerPlaceholder(),
                              errorWidget: (c, u, e) => Container(
                                color: AppColors.surfaceAlt,
                                child: const AppIcon(
                                    AppIcons.photo_library_outlined),
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
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
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
          actions: [IconButton(onPressed: () => context.push('/upload-portfolio'), icon: const AppIcon(AppIcons.add_rounded))],
        ),
        body: body,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [IconButton(onPressed: () => context.push('/upload-portfolio'), icon: const AppIcon(AppIcons.add_rounded))],
      ),
      body: body,
    );
  }
}
