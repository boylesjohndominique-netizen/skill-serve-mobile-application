import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/marketplace_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/cards/provider_card.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/widgets/inputs/app_search_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _recentSearches = ['Plumbing', 'Electrician near me', 'Math tutor', 'Wedding photographer'];

  @override
  Widget build(BuildContext context) {
    final marketplace = context.watch<MarketplaceController>();
    final hasQuery = marketplace.searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: AppSearchBar(
          hint: 'Search services or providers…',
          onChanged: (q) => context.read<MarketplaceController>().search(q),
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad, vertical: AppSizes.lg),
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
                            final provider = marketplace.providers[i];
                            return ProviderCard(
                              provider: provider,
                              onTap: () => context.push('/provider-preview/${provider.id}'),
                            );
                          },
                        ),
        ),
      ),
    );
  }
}
