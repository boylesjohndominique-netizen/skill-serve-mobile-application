import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cards/section_card.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/app_avatar.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../provider/controllers/portfolio_controller.dart';
import '../../provider/models/portfolio_model.dart';
import '../models/provider_model.dart';
import '../services/catalog_updates.dart';
import '../services/service_service.dart';

/// One piece of work in full: its photos (swipe, tap for full screen and
/// zoom), title, date and description.
///
/// The same screen for both roles. A customer ([providerId] set) reads it
/// from the provider's public profile, follows catalog changes live, and can
/// open the provider's profile. The provider ([providerId] null) reads it
/// from their own portfolio and can edit or delete it.
class PortfolioItemScreen extends StatefulWidget {
  final String itemId;
  final String? providerId;

  const PortfolioItemScreen.public({super.key, required String this.providerId, required this.itemId});

  const PortfolioItemScreen.mine({super.key, required this.itemId}) : providerId = null;

  bool get isMine => providerId == null;

  @override
  State<PortfolioItemScreen> createState() => _PortfolioItemScreenState();
}

class _PortfolioItemScreenState extends State<PortfolioItemScreen> {
  ProviderModel? _provider;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.isMine) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final portfolio = context.read<PortfolioController>();
        if (portfolio.find(widget.itemId) == null) await portfolio.loadMine();
        if (mounted) setState(() => _loading = false);
      });
    } else {
      CatalogUpdates.instance.addListener(_onCatalogChanged);
      _loadPublic();
    }
  }

  @override
  void dispose() {
    if (!widget.isMine) CatalogUpdates.instance.removeListener(_onCatalogChanged);
    super.dispose();
  }

  /// The provider added, edited or removed work: re-read it in place.
  void _onCatalogChanged() {
    if (!_loading) _loadPublic(silent: true);
  }

  Future<void> _loadPublic({bool silent = false}) async {
    if (!silent) setState(() => _failed = false);
    try {
      final provider = await ServiceService().getProviderById(widget.providerId!);
      if (mounted) setState(() => _provider = provider);
    } catch (_) {
      if (mounted && !silent) setState(() => _failed = true);
    }
    if (mounted) setState(() => _loading = false);
  }

  PortfolioModel? get _item {
    if (widget.isMine) return context.watch<PortfolioController>().find(widget.itemId);
    for (final item in _provider?.portfolio ?? const <PortfolioModel>[]) {
      if (item.id == widget.itemId) return item;
    }
    return null;
  }

  Future<void> _delete(PortfolioModel item) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Delete this work?',
      message: '"${item.title}" and its ${item.photoCount} ${item.photoCount == 1 ? 'photo' : 'photos'} will be removed from your public profile. This cannot be undone.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!confirmed || !mounted) return;
    final portfolio = context.read<PortfolioController>();
    final removed = await portfolio.remove(item.id);
    if (!mounted) return;
    if (removed) {
      AppSnackbar.success(context, 'Removed from your portfolio.');
      context.pop();
    } else {
      AppSnackbar.error(context, portfolio.errorMessage ?? 'We could not remove that item.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingState());
    if (_failed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Portfolio')),
        body: ErrorState(message: 'We could not load this work.', onRetry: _loadPublic),
      );
    }

    final item = _item;
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Portfolio')),
        body: const EmptyState(
          icon: AppIcons.photo_library_outlined,
          title: 'No longer available',
          message: 'This work has been removed from the profile.',
        ),
      );
    }

    final provider = _provider;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          if (widget.isMine) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const AppIcon(AppIcons.edit_outlined),
              onPressed: () => context.push('/edit-portfolio/${item.id}'),
            ),
            IconButton(
              tooltip: 'Delete',
              icon: AppIcon(AppIcons.delete_outline_rounded, color: context.errorColor),
              onPressed: () => _delete(item),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            _PhotoViewer(urls: item.photoUrls).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: AppSizes.lg),
            Text(item.title, style: AppTextStyles.headlineLarge),
            const SizedBox(height: 4),
            Text(
              [
                if (item.createdAt != null) 'Added ${Formatters.dateShort(item.createdAt!)}',
                '${item.photoCount} ${item.photoCount == 1 ? 'photo' : 'photos'}',
              ].join(' · '),
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSizes.lg),
            SectionCard(
              title: 'About this work',
              child: Text(
                item.description.trim().isEmpty ? 'No description was added.' : item.description,
                style: AppTextStyles.bodyLarge,
              ),
            ),
            if (provider != null) ...[
              const SizedBox(height: AppSizes.lg),
              SectionCard(
                title: 'Done by',
                child: InkWell(
                  onTap: () => context.push('/provider-profile/${provider.id}'),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  child: Row(
                    children: [
                      AppAvatar(
                        initials: provider.user.initials,
                        photoUrl: provider.user.profilePicture,
                        radius: 20,
                        backgroundColor: context.accentSoftColor,
                        foregroundColor: context.onAccentSoftColor,
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(provider.user.fullName, style: AppTextStyles.titleMedium, overflow: TextOverflow.ellipsis),
                            Text('View profile, services and reviews', style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      AppIcon(AppIcons.chevron_right_rounded, color: context.textMutedColor),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }
}

/// The item's photos: swipe between them, tap one for full screen (with
/// zoom), or pick one from the strip below.
class _PhotoViewer extends StatefulWidget {
  final List<String> urls;
  const _PhotoViewer({required this.urls});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _openFullScreen(int start) {
    Navigator.of(context).push(PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _FullScreenPhotos(urls: widget.urls, initial: start),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls;
    if (urls.isEmpty) {
      return Container(
        height: 280,
        decoration: BoxDecoration(color: context.accentSoftColor, borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
        child: AppIcon(AppIcons.photo_library_outlined, color: context.onAccentSoftColor, size: 40),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: SizedBox(
            height: 300,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pages,
                  itemCount: urls.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => Semantics(
                    button: true,
                    label: 'Photo ${i + 1} of ${urls.length}. Open full screen',
                    child: GestureDetector(
                      onTap: () => _openFullScreen(i),
                      child: CachedNetworkImage(
                        imageUrl: urls[i],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, __) => const ShimmerPlaceholder(),
                        errorWidget: (_, __, ___) => Container(
                          color: context.surfaceAltColor,
                          child: AppIcon(AppIcons.broken_image_outlined, color: context.textMutedColor),
                        ),
                      ),
                    ),
                  ),
                ),
                if (urls.length > 1)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                      ),
                      child: Text(
                        '${_index + 1}/${urls.length}',
                        style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (urls.length > 1) ...[
          const SizedBox(height: AppSizes.sm),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _pages.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: i == _index ? context.accentInk : Colors.transparent, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd - 2),
                    child: CachedNetworkImage(imageUrl: urls[i], fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FullScreenPhotos extends StatelessWidget {
  final List<String> urls;
  final int initial;
  const _FullScreenPhotos({required this.urls, required this.initial});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: PageView.builder(
        controller: PageController(initialPage: initial),
        itemCount: urls.length,
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(child: CachedNetworkImage(imageUrl: urls[i], fit: BoxFit.contain)),
        ),
      ),
    );
  }
}
