import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/marketplace_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/cards/category_card.dart';
import '../../core/widgets/cards/provider_card.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/widgets/inputs/app_search_bar.dart';
import '../../core/widgets/misc/section_header.dart';
import '../../data/mock/mock_data.dart';
import '../../models/booking_model.dart';

/// Client's primary landing tab — greeting, quick search, categories,
/// an active-booking summary strip, and a top-rated providers list.
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final marketplace = context.read<MarketplaceController>();
      if (marketplace.providers.isEmpty) marketplace.loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final marketplace = context.watch<MarketplaceController>();
    final favorites = context.watch<FavoritesController>();

    final upcoming = MockData.bookingsForClient
        .where((b) => b.status == BookingStatus.confirmed || b.status == BookingStatus.pending)
        .toList();

    final topRated = [...marketplace.providers]..sort((a, b) => b.averageRating.compareTo(a.averageRating));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => marketplace.loadInitial(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad, vertical: AppSizes.lg),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SkillLink', style: AppTextStyles.displayMedium),
                  InkWell(
                    onTap: () => context.push('/notifications'),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(999)),
                      child: const Icon(Icons.notifications_outlined, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              AppSearchBar(readOnly: true, onTap: () => context.push('/search')),

              const SizedBox(height: AppSizes.lg),
              PrimaryButton(
                label: 'Book a service',
                icon: Icons.calendar_month_rounded,
                onPressed: () => context.push('/browse'),
              ),

              if (upcoming.isNotEmpty) ...[
                const SizedBox(height: AppSizes.xl),
                Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                        child: const Icon(Icons.event_available_rounded, color: AppColors.secondary, size: 22),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${upcoming.length} upcoming booking${upcoming.length > 1 ? 's' : ''}',
                                style: AppTextStyles.onDark(AppTextStyles.titleMedium)),
                            Text(upcoming.first.serviceTitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/booking-details/${upcoming.first.id}'),
                        child: Text('View', style: AppTextStyles.button.copyWith(color: AppColors.secondary)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSizes.xl),
              const SectionHeader(title: 'Categories'),
              const SizedBox(height: AppSizes.md),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: marketplace.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
                  itemBuilder: (context, i) {
                    final cat = marketplace.categories[i];
                    return CategoryCard(
                      category: cat,
                      onTap: () async {
                        await marketplace.filterByCategory(cat.name);
                        if (context.mounted) context.push('/browse');
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSizes.xl),
              SectionHeader(title: 'Top Rated Providers', actionLabel: 'See all', onAction: () => context.push('/browse')),
              const SizedBox(height: AppSizes.md),
              if (marketplace.isLoading)
                const ShimmerCardList(count: 4, itemHeight: 100)
              else
                Column(
                  children: [
                    for (final prov in topRated.take(5))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.md),
                        child: ProviderCard(
                          provider: prov,
                          isFavorite: favorites.isFavorite(prov.id),
                          onFavoriteToggle: () => favorites.toggle(prov.id),
                          onTap: () => context.push('/provider-profile/${prov.id}'),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
