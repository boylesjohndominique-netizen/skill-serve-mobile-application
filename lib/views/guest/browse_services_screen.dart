import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/marketplace_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/cards/category_card.dart';
import '../../core/widgets/cards/provider_card.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/widgets/inputs/app_search_bar.dart';
import '../../core/widgets/misc/section_header.dart';
import '../../models/category_model.dart';

/// Guest-accessible marketplace browser. Booking a provider from here
/// prompts a login (see ProviderPreviewScreen).
class BrowseServicesScreen extends StatefulWidget {
  const BrowseServicesScreen({super.key});

  @override
  State<BrowseServicesScreen> createState() => _BrowseServicesScreenState();
}

class _BrowseServicesScreenState extends State<BrowseServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketplaceController>().loadInitial();
    });
  }

  @override
  Widget build(BuildContext context) {
    final marketplace = context.watch<MarketplaceController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Services'),
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text('Log in', style: AppTextStyles.button.copyWith(color: AppColors.secondary)),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<MarketplaceController>().loadInitial(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad, vertical: AppSizes.lg),
            children: [
              AppSearchBar(onTap: () => context.push('/search'), readOnly: true),
              const SizedBox(height: AppSizes.xl),
              const SectionHeader(title: 'Categories'),
              const SizedBox(height: AppSizes.md),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: marketplace.categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return CategoryCard(
                        category: const CategoryModel(id: 'all', name: 'All', icon: 'work'),
                        selected: marketplace.selectedCategory == 'All',
                        onTap: () => context.read<MarketplaceController>().filterByCategory('All'),
                      );
                    }
                    final cat = marketplace.categories[i - 1];
                    return CategoryCard(
                      category: cat,
                      selected: marketplace.selectedCategory == cat.name,
                      onTap: () => context.read<MarketplaceController>().filterByCategory(cat.name),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              SectionHeader(title: 'Available Providers', actionLabel: 'See all', onAction: () => context.push('/categories')),
              const SizedBox(height: AppSizes.md),
              if (marketplace.isLoading)
                const ShimmerCardList(count: 5, itemHeight: 100)
              else if (marketplace.providers.isEmpty)
                const EmptyState(icon: Icons.search_off_rounded, title: 'No providers found', message: 'Try a different category or search term.')
              else
                Column(
                  children: [
                    for (final provider in marketplace.providers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.md),
                        child: ProviderCard(
                          provider: provider,
                          onTap: () => context.push('/provider-preview/${provider.id}'),
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
