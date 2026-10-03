import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cards/provider_card.dart';
import '../../../core/widgets/cards/service_card.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/inputs/app_search_bar.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/section_header.dart';
import '../controllers/discovery_controller.dart';
import '../controllers/favorites_controller.dart';
import 'favorite_toggle.dart';
import '../models/discovery_filters.dart';
import '../models/provider_model.dart';
import 'widgets/discovery_filter_sheet.dart';
import '../../../core/theme/app_palette.dart';

/// Explore — one search box over services and providers, with suggestions,
/// recent searches, and the featured and top-rated rails shown before a
/// search is made.
class ClientSearchScreen extends StatefulWidget {
  const ClientSearchScreen({super.key});

  @override
  State<ClientSearchScreen> createState() => _ClientSearchScreenState();
}

class _ClientSearchScreenState extends State<ClientSearchScreen> {
  final _queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // The controller outlives this screen, so a remount restores the term
    // whose results are still on screen.
    _queryController.text = context.read<DiscoveryController>().query;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiscoveryController>().initialize();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _runSearch(String term) {
    _queryController.text = term;
    context.read<DiscoveryController>().submit(term);
    FocusScope.of(context).unfocus();
  }

  Future<void> _openFilters() async {
    final discovery = context.read<DiscoveryController>();
    final updated = await showDiscoveryFilterSheet(
      context,
      filters: discovery.filters,
      categories: discovery.categories,
    );
    if (updated != null) await discovery.applyFilters(updated);
  }

  @override
  Widget build(BuildContext context) {
    final discovery = context.watch<DiscoveryController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad, vertical: AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Explore', style: AppTextStyles.displayMedium)
                  .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
              Text('Search every service and provider on SkillServe.', style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSizes.md),
              AppSearchBar(
                controller: _queryController,
                onChanged: discovery.onQueryChanged,
                onSubmitted: (value) => _runSearch(value),
                onFilterTap: _openFilters,
                activeFilterCount: discovery.filters.activeCount,
              ).animate().fadeIn(delay: 80.ms, duration: 300.ms),
              if (!discovery.filters.isEmpty) ...[
                const SizedBox(height: AppSizes.sm),
                _ActiveFilterSummary(
                  discovery: discovery,
                  onClear: discovery.clearFilters,
                ),
              ],
              const SizedBox(height: AppSizes.lg),
              Expanded(child: _Body(discovery: discovery, onSearchTerm: _runSearch)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final DiscoveryController discovery;
  final ValueChanged<String> onSearchTerm;

  const _Body({required this.discovery, required this.onSearchTerm});

  @override
  Widget build(BuildContext context) {
    if (discovery.error != null) {
      return ErrorState(message: discovery.error!, onRetry: discovery.retry);
    }
    if (!discovery.hasQuery) {
      return _IdleDiscovery(discovery: discovery, onSearchTerm: onSearchTerm);
    }
    return _Results(discovery: discovery, onSearchTerm: onSearchTerm);
  }
}

/// What the Explore tab shows before a search: recent terms plus the
/// administrator-curated featured and top-rated providers.
class _IdleDiscovery extends StatelessWidget {
  final DiscoveryController discovery;
  final ValueChanged<String> onSearchTerm;

  const _IdleDiscovery({required this.discovery, required this.onSearchTerm});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: context.accentInk,
      onRefresh: discovery.loadHighlights,
      child: ListView(
        children: [
          if (discovery.recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent searches', style: AppTextStyles.titleLarge),
                TextButton(
                  onPressed: discovery.clearRecents,
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final term in discovery.recentSearches)
                  InputChip(
                    label: Text(term),
                    avatar: AppIcon(AppIcons.history_rounded, size: 16, color: context.textMutedColor),
                    onPressed: () => onSearchTerm(term),
                    onDeleted: () => discovery.removeRecent(term),
                    deleteIcon: const AppIcon(AppIcons.close_rounded, size: 14),
                    deleteButtonTooltipMessage: 'Remove $term from recent searches',
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.xl),
          ],
          const SectionHeader(title: 'Featured providers', eyebrow: 'Picked by SkillServe'),
          const SizedBox(height: AppSizes.md),
          if (discovery.isLoadingHighlights)
            const ShimmerCardList(count: 2, itemHeight: 100)
          else if (discovery.featuredProviders.isEmpty)
            const EmptyState(
              icon: AppIcons.workspace_premium_outlined,
              title: 'No featured providers yet',
              message: 'Providers highlighted by the SkillServe team will appear here.',
            )
          else
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: discovery.featuredProviders.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
                itemBuilder: (context, i) => SizedBox(
                  width: 272,
                  child: _ProviderResult(provider: discovery.featuredProviders[i]),
                ),
              ),
            ),
          const SizedBox(height: AppSizes.xl),
          const SectionHeader(title: 'Top-rated providers', eyebrow: 'Highest rated on SkillServe'),
          const SizedBox(height: AppSizes.md),
          if (discovery.isLoadingHighlights)
            const ShimmerCardList(count: 3, itemHeight: 100)
          else if (discovery.topRatedProviders.isEmpty)
            const EmptyState(
              icon: AppIcons.star_outline_rounded,
              title: 'No rated providers yet',
              message: 'Providers appear here once clients start reviewing their work.',
            )
          else
            for (final provider in discovery.topRatedProviders)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.md),
                child: _ProviderResult(provider: provider),
              ),
          const SizedBox(height: AppSizes.xxl),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  final DiscoveryController discovery;
  final ValueChanged<String> onSearchTerm;

  const _Results({required this.discovery, required this.onSearchTerm});

  @override
  Widget build(BuildContext context) {
    final suggestions = discovery.suggestions;

    return ListView(
      children: [
        if (suggestions.isNotEmpty) ...[
          Text('Suggestions', style: AppTextStyles.eyebrow),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in suggestions)
                ActionChip(
                  label: Text(suggestion),
                  avatar: AppIcon(AppIcons.manage_search_rounded, size: 16, color: context.textMutedColor),
                  onPressed: () => onSearchTerm(suggestion),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
        ],
        if (discovery.isLoading)
          const ShimmerCardList(count: 5, itemHeight: 100)
        else if (!discovery.hasResults)
          EmptyState(
            icon: AppIcons.search_off_rounded,
            title: 'No results found',
            message: 'Nothing matched "${discovery.query.trim()}". Try another term or adjust your filters.',
          )
        else ...[
          if (discovery.services.isNotEmpty) ...[
            SectionHeader(title: 'Services', eyebrow: '${discovery.services.length} found'),
            const SizedBox(height: AppSizes.md),
            for (final service in discovery.services)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.md),
                child: ServiceCard(
                  service: service,
                  onTap: () => context.push('/service-details/${service.id}'),
                ),
              ),
            const SizedBox(height: AppSizes.lg),
          ],
          if (discovery.providers.isNotEmpty) ...[
            SectionHeader(title: 'Providers', eyebrow: '${discovery.providers.length} found'),
            const SizedBox(height: AppSizes.md),
            for (final provider in discovery.providers)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.md),
                child: _ProviderResult(provider: provider),
              ),
          ],
        ],
        const SizedBox(height: AppSizes.xxl),
      ],
    );
  }
}

/// A provider row wired to the favorites toggle and the public profile.
class _ProviderResult extends StatelessWidget {
  final ProviderModel provider;

  const _ProviderResult({required this.provider});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();

    return ProviderCard(
      provider: provider,
      isFavorite: favorites.isFavorite(provider.id),
      onFavoriteToggle: () => toggleFavorite(context, provider),
      onTap: () => context.push('/provider-profile/${provider.id}'),
    );
  }
}

class _ActiveFilterSummary extends StatelessWidget {
  final DiscoveryController discovery;
  final VoidCallback onClear;

  const _ActiveFilterSummary({required this.discovery, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final filters = discovery.filters;
    final labels = <String>[
      if (filters.category != null) filters.category!.name,
      if (filters.minRating != null) '${DiscoveryFilters.ratingLabel(filters.minRating!)} stars',
      if (filters.featuredOnly) 'Featured',
      if (filters.availableOnly) 'Available now',
      if (filters.availableDay != null) 'Works ${filters.availableDayLabel}s',
      if (filters.sort != DiscoverySort.newest) filters.sort.label,
    ];

    return Row(
      children: [
        Expanded(
          child: Text(
            labels.join(' • '),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryDeep),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(onPressed: onClear, child: const Text('Clear')),
      ],
    );
  }
}
