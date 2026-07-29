import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/marketplace_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/cards/provider_card.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/widgets/inputs/app_search_bar.dart';

/// Client's Search tab — same behavior as the guest Search screen, but
/// results route into the authenticated Provider Profile (with booking).
class ClientSearchScreen extends StatefulWidget {
  const ClientSearchScreen({super.key});

  @override
  State<ClientSearchScreen> createState() => _ClientSearchScreenState();
}

class _ClientSearchScreenState extends State<ClientSearchScreen> {
  final _recentSearches = ['Plumbing', 'Electrician near me', 'Math tutor', 'Wedding photographer'];

  @override
  Widget build(BuildContext context) {
    final marketplace = context.watch<MarketplaceController>();
    final favorites = context.watch<FavoritesController>();
    final hasQuery = marketplace.searchQuery.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad, vertical: AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Search', style: AppTextStyles.displayMedium),
              const SizedBox(height: AppSizes.md),
              AppSearchBar(onChanged: (q) => context.read<MarketplaceController>().search(q)),
              const SizedBox(height: AppSizes.xl),
              Expanded(
                child: !hasQuery
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recent searches', style: AppTextStyles.titleLarge),
                          const SizedBox(height: AppSizes.md),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final term in _recentSearches)
                                ActionChip(
                                  label: Text(term),
                                  onPressed: () => context.read<MarketplaceController>().search(term),
                                  avatar: const Icon(Icons.history_rounded, size: 16, color: AppColors.textMuted),
                                ),
                            ],
                          ),
                        ],
                      )
                    : marketplace.isLoading
                        ? const ShimmerCardList(count: 5, itemHeight: 100)
                        : marketplace.providers.isEmpty
                            ? const EmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'No results found',
                                message: 'Try searching a different service or provider name.',
                              )
                            : ListView.separated(
                                itemCount: marketplace.providers.length,
                                separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                                itemBuilder: (context, i) {
                                  final p = marketplace.providers[i];
                                  return ProviderCard(
                                    provider: p,
                                    isFavorite: favorites.isFavorite(p.id),
                                    onFavoriteToggle: () => favorites.toggle(p.id),
                                    onTap: () => context.push('/provider-profile/${p.id}'),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
