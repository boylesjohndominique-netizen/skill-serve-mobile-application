import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../provider/controllers/portfolio_controller.dart';
import '../models/portfolio_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cards/portfolio_card.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// The provider's own portfolio: each piece of work as a card (cover, photo
/// count, title, date). Tap one to see it, edit it or delete it.
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
    final items = controller.items;
    final photos = items.fold<int>(0, (sum, item) => sum + item.photoCount);

    final Widget body;
    if (controller.isLoading && items.isEmpty) {
      body = const Padding(padding: EdgeInsets.all(AppSizes.pageHPad), child: ShimmerCardList(itemHeight: 160));
    } else if (controller.errorMessage != null && items.isEmpty) {
      body = ErrorState(message: controller.errorMessage!, onRetry: controller.loadMine);
    } else if (items.isEmpty) {
      body = EmptyState(
        icon: AppIcons.photo_library_outlined,
        title: 'Showcase your work',
        message: 'Add photos of services you completed — up to ${PortfolioModel.maxPhotos} per piece of work — to build trust with future customers.',
        actionLabel: 'Add work',
        onAction: () => context.push('/upload-portfolio'),
      );
    } else {
      body = RefreshIndicator(
        color: context.accentInk,
        onRefresh: controller.loadMine,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSizes.pageHPad, AppSizes.md, AppSizes.pageHPad, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '${items.length} ${items.length == 1 ? 'piece of work' : 'pieces of work'} · $photos ${photos == 1 ? 'photo' : 'photos'} · tap one to see, edit or delete it',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSizes.pageHPad, AppSizes.md, AppSizes.pageHPad, 96),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSizes.md,
                  crossAxisSpacing: AppSizes.md,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => PortfolioCard(
                    item: items[i],
                    onTap: () => context.push('/my-portfolio/${items[i].id}'),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 50), duration: 300.ms)
                      .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutCubic),
                  childCount: items.length,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        automaticallyImplyLeading: !widget.embedded,
        actions: [
          IconButton(
            tooltip: 'Add work',
            onPressed: () => context.push('/upload-portfolio'),
            icon: const AppIcon(AppIcons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/upload-portfolio'),
              icon: const AppIcon(AppIcons.add_photo_alternate_outlined, color: AppColors.primary),
              label: Text('Add work', style: AppTextStyles.button.copyWith(color: AppColors.primary)),
              backgroundColor: AppColors.secondary,
            ),
      body: SafeArea(child: body),
    );
  }
}
