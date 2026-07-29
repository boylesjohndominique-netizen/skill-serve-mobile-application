import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/marketplace_controller.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/cards/provider_card.dart';
import '../../core/widgets/feedback/empty_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();
    final marketplace = context.watch<MarketplaceController>();
    final favoriteProviders = marketplace.providers.where((p) => favorites.isFavorite(p.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favorite Providers')),
      body: SafeArea(
        child: favoriteProviders.isEmpty
            ? const EmptyState(
                icon: Icons.favorite_border_rounded,
                title: 'No favorites yet',
                message: 'Tap the heart icon on a provider to save them here for quick access.',
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSizes.pageHPad),
                itemCount: favoriteProviders.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                itemBuilder: (context, i) {
                  final p = favoriteProviders[i];
                  return ProviderCard(
                    provider: p,
                    isFavorite: true,
                    onFavoriteToggle: () => favorites.toggle(p.id),
                    onTap: () => context.push('/provider-profile/${p.id}'),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                      .slideY(begin: 0.06, end: 0);
                },
              ),
      ),
    );
  }
}
