import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../marketplace/controllers/favorites_controller.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/cards/provider_card.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/constants/app_icons.dart';
import 'favorite_toggle.dart';

/// The customer's saved providers, as the server keeps them.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();
    final saved = favorites.providers;

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Providers')),
      body: SafeArea(
        child: favorites.isLoading && saved.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pageHPad),
                child: ShimmerCardList(itemHeight: 110),
              )
            : favorites.errorMessage != null && saved.isEmpty
                ? ErrorState(message: favorites.errorMessage!, onRetry: favorites.load)
                : RefreshIndicator(
                    onRefresh: favorites.load,
                    child: saved.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              EmptyState(
                                icon: AppIcons.favorite_border_rounded,
                                title: 'No favorites yet',
                                message: 'Tap the heart icon on a provider to save them here for quick access.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(AppSizes.pageHPad),
                            itemCount: saved.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                            itemBuilder: (context, i) {
                              final p = saved[i];
                              return ProviderCard(
                                provider: p,
                                isFavorite: true,
                                onFavoriteToggle: () => toggleFavorite(context, p),
                                onTap: () => context.push('/provider-profile/${p.id}'),
                              )
                                  .animate()
                                  .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                                  .slideY(begin: 0.06, end: 0);
                            },
                          ),
                  ),
      ),
    );
  }
}
