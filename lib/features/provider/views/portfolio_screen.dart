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
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// The provider's own portfolio: each piece of work as a card (cover, photo
/// count, title, date). Tap one to see it, edit it or delete it; the trash
/// button selects several to delete at once. Work is added with the
/// floating "Add work" button.
class ProviderPortfolioScreen extends StatefulWidget {
  final bool embedded;
  const ProviderPortfolioScreen({super.key, this.embedded = false});

  @override
  State<ProviderPortfolioScreen> createState() => _ProviderPortfolioScreenState();
}

class _ProviderPortfolioScreenState extends State<ProviderPortfolioScreen> {
  /// Selecting work to delete; null when not.
  Set<String>? _selected;
  bool _deleting = false;

  bool get _selecting => _selected != null;

  void _toggle(String id) => setState(() {
        final selected = _selected!;
        selected.contains(id) ? selected.remove(id) : selected.add(id);
      });

  Future<void> _deleteSelected() async {
    final ids = _selected ?? const <String>{};
    if (ids.isEmpty) return;
    final count = ids.length;
    final confirmed = await AppDialog.confirm(
      context,
      title: count == 1 ? 'Delete this work?' : 'Delete $count pieces of work?',
      message: 'They will be removed from your public profile with all their photos. This cannot be undone.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!confirmed || !mounted) return;

    final portfolio = context.read<PortfolioController>();
    setState(() => _deleting = true);
    final removed = await portfolio.removeMany(ids);
    if (!mounted) return;
    setState(() {
      _deleting = false;
      _selected = null;
    });
    if (removed == count) {
      AppSnackbar.success(context, removed == 1 ? 'Deleted.' : '$removed pieces of work deleted.');
    } else {
      AppSnackbar.error(context, '${count - removed} could not be deleted. ${portfolio.errorMessage ?? ''}'.trim());
    }
  }

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
                  (context, i) => _SelectableCard(
                    selected: _selected?.contains(items[i].id),
                    child: PortfolioCard(
                      item: items[i],
                      onTap: _selecting
                          ? () => _toggle(items[i].id)
                          : () => context.push('/my-portfolio/${items[i].id}'),
                    ),
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

    final selected = _selected;
    return Scaffold(
      appBar: selected != null
          ? AppBar(
              leading: IconButton(
                tooltip: 'Cancel',
                icon: const AppIcon(AppIcons.close_rounded),
                onPressed: _deleting ? null : () => setState(() => _selected = null),
              ),
              title: Text(selected.isEmpty ? 'Select work to delete' : '${selected.length} selected'),
              actions: [
                IconButton(
                  tooltip: 'Delete selected',
                  icon: AppIcon(AppIcons.delete_outline_rounded, color: selected.isEmpty ? null : context.errorColor),
                  onPressed: selected.isEmpty || _deleting ? null : _deleteSelected,
                ),
              ],
            )
          : AppBar(
              title: const Text('Portfolio'),
              automaticallyImplyLeading: !widget.embedded,
              actions: [
                if (items.isNotEmpty)
                  IconButton(
                    tooltip: 'Delete work',
                    onPressed: () => setState(() => _selected = <String>{}),
                    icon: const AppIcon(AppIcons.delete_outline_rounded),
                  ),
              ],
            ),
      floatingActionButton: items.isEmpty || _selecting
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

/// A portfolio card that shows a tick box while work is being selected
/// ([selected] non-null).
class _SelectableCard extends StatelessWidget {
  final bool? selected;
  final Widget child;
  const _SelectableCard({required this.selected, required this.child});

  @override
  Widget build(BuildContext context) {
    final isSelected = selected;
    if (isSelected == null) return child;
    return Stack(
      children: [
        Positioned.fill(child: child),
        if (isSelected)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: context.errorColor, width: 2.5),
                  color: context.errorColor.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
        Positioned(
          top: 8,
          left: 8,
          child: IgnorePointer(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? context.errorColor : Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: isSelected ? const AppIcon(AppIcons.check_rounded, size: 14, color: Colors.white) : null,
            ),
          ),
        ),
      ],
    );
  }
}
