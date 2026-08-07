import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

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
              Text('Search', style: AppTextStyles.displayMedium)
                  .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: AppSizes.md),
              AppSearchBar(onChanged: (q) => context.read<MarketplaceController>().search(q))
                  .animate().fadeIn(delay: 80.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.xl),
              Expanded(
                child: !hasQuery
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Recent searches', style: AppTextStyles.titleLarge)
                              .animate().fadeIn(delay: 150.ms, duration: 300.ms),
                          const SizedBox(height: AppSizes.md),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (var i = 0; i < _recentSearches.length; i++)
                                ActionChip(
                                  label: Text(_recentSearches[i]),
                                  onPressed: () => context.read<MarketplaceController>().search(_recentSearches[i]),
                                  avatar: const AppIcon(AppIcons.history_rounded, size: 16, color: AppColors.textMuted),
                                )
                                    .animate()
                                    .fadeIn(delay: Duration(milliseconds: 200 + i * 60), duration: 300.ms)
                                    .slideX(begin: 0.1, end: 0),
                            ],
                          ),
                        ],
                      )
                    : marketplace.isLoading
                        ? const ShimmerCardList(count: 5, itemHeight: 100)
                        : marketplace.providers.isEmpty
                            ? const EmptyState(
                                icon: AppIcons.search_off_rounded,
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
                                  )
                                      .animate()
                                      .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                                      .slideY(begin: 0.06, end: 0);
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
