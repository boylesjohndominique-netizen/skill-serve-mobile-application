import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cards/portfolio_card.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../models/provider_model.dart';
import '../services/catalog_updates.dart';
import '../services/service_service.dart';

/// A provider's whole portfolio for customers: each piece of work as a card;
/// tap one for its photos and details. Live — work the provider adds or
/// removes appears without reopening.
class PortfolioGalleryScreen extends StatefulWidget {
  final String providerId;
  const PortfolioGalleryScreen({super.key, required this.providerId});

  @override
  State<PortfolioGalleryScreen> createState() => _PortfolioGalleryScreenState();
}

class _PortfolioGalleryScreenState extends State<PortfolioGalleryScreen> {
  ProviderModel? _provider;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    CatalogUpdates.instance.addListener(_onCatalogChanged);
    _load();
  }

  @override
  void dispose() {
    CatalogUpdates.instance.removeListener(_onCatalogChanged);
    super.dispose();
  }

  void _onCatalogChanged() {
    if (_provider != null) _load(silent: true);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _failed = false);
    try {
      final provider = await ServiceService().getProviderById(widget.providerId);
      if (mounted) setState(() => _provider = provider);
    } catch (_) {
      if (mounted && !silent) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Portfolio')),
        body: ErrorState(message: 'We could not load this portfolio.', onRetry: _load),
      );
    }
    final provider = _provider;
    if (provider == null) return const Scaffold(body: LoadingState());
    final items = provider.portfolio;
    final photos = items.fold<int>(0, (sum, item) => sum + item.photoCount);

    return Scaffold(
      appBar: AppBar(title: Text('${provider.user.fullName}\'s work', overflow: TextOverflow.ellipsis)),
      body: SafeArea(
        child: items.isEmpty
            ? const EmptyState(
                icon: AppIcons.photo_library_outlined,
                title: 'No portfolio yet',
                message: 'This provider hasn\'t added any work yet.',
              )
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSizes.pageHPad, AppSizes.md, AppSizes.pageHPad, 0),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        '${items.length} ${items.length == 1 ? 'piece of work' : 'pieces of work'} · $photos ${photos == 1 ? 'photo' : 'photos'}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(AppSizes.pageHPad),
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
                          onTap: () => context.push('/portfolio-item/${provider.id}/${items[i].id}'),
                        ).animate().fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 50), duration: 300.ms),
                        childCount: items.length,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
