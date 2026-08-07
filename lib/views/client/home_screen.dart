import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/favorites_controller.dart';
import '../../controllers/marketplace_controller.dart';
import '../../core/constants/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/widgets/misc/section_header.dart';
import '../../core/widgets/misc/verification_seal.dart';
import '../../data/mock/mock_data.dart';
import '../../models/booking_model.dart';
import '../../models/provider_model.dart';
import '../../services/service_service.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

/// Client's primary landing tab — the SkillServe "Discover" experience:
/// hero, category chips, featured strip, and a 2-column provider grid.
class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  String _selectedCategory = 'All';
  List<ProviderModel> _featured = [];
  bool _featuredLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final marketplace = context.read<MarketplaceController>();
      if (marketplace.providers.isEmpty) marketplace.loadInitial();
      ServiceService().getFeaturedProviders().then((f) {
        if (mounted) {
          setState(() {
            _featured = f;
            _featuredLoading = false;
          });
        }
      });
    });
  }

  Future<void> _refresh() async {
    final marketplace = context.read<MarketplaceController>();
    await marketplace.loadInitial();
    final featured = await ServiceService().getFeaturedProviders();
    if (mounted) setState(() => _featured = featured);
  }

  @override
  Widget build(BuildContext context) {
    final marketplace = context.watch<MarketplaceController>();
    final favorites = context.watch<FavoritesController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final upcoming = MockData.bookingsForClient
        .where((b) => b.status == BookingStatus.confirmed || b.status == BookingStatus.pending)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad, vertical: AppSizes.lg),
            children: [
              // ── Brand header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SkillServe', style: AppTextStyles.displayMedium)
                          .animate().fadeIn(duration: 300.ms).slideX(begin: -0.06, end: 0),
                      Text('Find trusted talent, fast.', style: AppTextStyles.bodySmall)
                          .animate().fadeIn(delay: 80.ms, duration: 300.ms),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.push('/notifications'),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const AppIcon(AppIcons.notifications_outlined, size: 20),
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms).scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),
                ],
              ),
              const SizedBox(height: AppSizes.lg),

              // ── Hero card ──
              const _DiscoverHero().animate().fadeIn(delay: 120.ms, duration: 450.ms).slideY(begin: 0.08, end: 0),

              // ── Upcoming booking banner ──
              if (upcoming.isNotEmpty) ...[
                const SizedBox(height: AppSizes.lg),
                Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6), width: 0.8),
                    boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.brassGradient,
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                        child: const AppIcon(AppIcons.event_available_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${upcoming.length} upcoming booking${upcoming.length > 1 ? 's' : ''}', style: AppTextStyles.titleMedium),
                            Text(upcoming.first.serviceTitle, style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/booking-details/${upcoming.first.id}'),
                        child: Text('View', style: AppTextStyles.button.copyWith(color: AppColors.secondary)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 220.ms, duration: 400.ms).slideY(begin: 0.06, end: 0),
              ],

              const SizedBox(height: AppSizes.xl),

              // ── Category chips ──
              const SectionHeader(title: 'Browse categories')
                  .animate().fadeIn(delay: 300.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.md),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: marketplace.categories.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
                  itemBuilder: (context, i) {
                    final name = i == 0 ? 'All' : marketplace.categories[i - 1].name;
                    final icon = i == 0
                        ? AppIcons.apps_rounded
                        : _categoryIcon(marketplace.categories[i - 1].icon);
                    return _CategoryChip(
                      label: name,
                      icon: icon,
                      selected: _selectedCategory == name,
                      onTap: () {
                        setState(() => _selectedCategory = name);
                        context.read<MarketplaceController>().filterByCategory(name);
                      },
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 350 + (i.clamp(0, 6) * 40)), duration: 300.ms)
                        .slideX(begin: 0.15, end: 0);
                  },
                ),
              ),

              // ── Featured strip ──
              const SizedBox(height: AppSizes.xl),
              const SectionHeader(title: 'Featured Pros', eyebrow: 'Verified & trusted')
                  .animate().fadeIn(delay: 420.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.md),
              if (_featuredLoading)
                SizedBox(
                  height: 168,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
                    itemBuilder: (_, __) => const ShimmerPlaceholder(width: 150, height: 168),
                  ),
                )
              else if (_featured.isEmpty)
                const EmptyState(icon: AppIcons.workspace_premium_outlined, title: 'No featured pros yet', message: 'Verified providers will appear here.')
              else
                SizedBox(
                  height: 168,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _featured.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSizes.md),
                    itemBuilder: (context, i) => _FeaturedCard(
                      provider: _featured[i],
                      onTap: () => context.push('/provider-profile/${_featured[i].id}'),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 460 + (i.clamp(0, 6) * 50)), duration: 350.ms)
                        .slideX(begin: 0.12, end: 0),
                  ),
                ),

              // ── Provider grid ──
              const SizedBox(height: AppSizes.xl),
              SectionHeader(
                title: 'Available providers',
                eyebrow: _selectedCategory == 'All' ? 'All categories' : _selectedCategory,
              ).animate().fadeIn(delay: 520.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.md),
              if (marketplace.isLoading)
                const ShimmerCardList(count: 4, itemHeight: 100)
              else if (marketplace.providers.isEmpty)
                const EmptyState(
                  icon: AppIcons.search_off_rounded,
                  title: 'No providers found',
                  message: 'Try a different category — or be the first to book when a pro joins.',
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSizes.md,
                    crossAxisSpacing: AppSizes.md,
                    childAspectRatio: 0.66,
                  ),
                  itemCount: marketplace.providers.length,
                  itemBuilder: (context, i) {
                    final p = marketplace.providers[i];
                    return _GridProviderCard(
                      provider: p,
                      isFavorite: favorites.isFavorite(p.id),
                      onFavoriteToggle: () => favorites.toggle(p.id),
                      onTap: () => context.push('/provider-profile/${p.id}'),
                      onBook: () => context.push('/booking-form/${p.id}'),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 560 + (i.clamp(0, 8) * 50)), duration: 350.ms)
                        .slideY(begin: 0.06, end: 0);
                  },
                ),
              const SizedBox(height: AppSizes.xxl),
            ],
          ),
        ),
      ),
    );
  }

  AppIconData _categoryIcon(String key) {
    switch (key) {
      case 'plumbing':
        return AppIcons.plumbing_rounded;
      case 'bolt':
        return AppIcons.bolt_rounded;
      case 'school':
        return AppIcons.school_rounded;
      case 'brush':
        return AppIcons.brush_rounded;
      case 'photo_camera':
        return AppIcons.photo_camera_rounded;
      case 'carpenter':
        return AppIcons.carpenter_rounded;
      default:
        return AppIcons.work_outline_rounded;
    }
  }
}

/// ─── Hero card: ink gradient, brass glow orbs, tagline, search ───
class _DiscoverHero extends StatelessWidget {
  const _DiscoverHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Brass glow orbs
          Positioned(
            top: -56,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.35),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -48,
            left: -36,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryLight.withValues(alpha: 0.12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryLight.withValues(alpha: 0.2),
                    blurRadius: 48,
                    spreadRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppIcon(AppIcons.verified_rounded, size: 14, color: AppColors.secondaryLight),
                        const SizedBox(width: 5),
                        Text(
                          'Verified local professionals',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textOnDark, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const VerificationSeal(status: 'verified', size: 34),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Find trusted\ntalent, fast.',
                style: AppTextStyles.onDark(AppTextStyles.displayLarge),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Book vetted pros for home repairs, tutoring, design & more across the Visayas.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMutedDark),
              ),
              const SizedBox(height: AppSizes.lg),
              // Search field → Search tab
              GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
                  ),
                  child: const Row(
                    children: [
                      AppIcon(AppIcons.search_rounded, color: Colors.white70, size: 20),
                      SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Search services or providers…',
                            style: TextStyle(color: Colors.white60, fontSize: 14),
                          ),
                        ),
                      ),
                      AppIcon(AppIcons.tune_rounded, color: AppColors.secondaryLight, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ─── Category filter chip (brass-filled when selected) ───
class _CategoryChip extends StatefulWidget {
  final String label;
  final AppIconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        child: AnimatedContainer(
          duration: AppAnimations.md,
          curve: AppAnimations.defaultCurve,
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 9),
          decoration: BoxDecoration(
            color: widget.selected ? AppColors.secondary : (isDark ? AppColors.surfaceAltDark : AppColors.surface),
            borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            border: Border.all(
              color: widget.selected ? AppColors.secondary : (isDark ? AppColors.lineDark : AppColors.line),
              width: widget.selected ? 0 : 1,
            ),
            boxShadow: widget.selected
                ? [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 3))]
                : AppSizes.shadowFor(context, level: ShadowLevel.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(widget.icon, size: 15, color: widget.selected ? Colors.white : AppColors.secondary),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: AppTextStyles.label.copyWith(
                  color: widget.selected ? Colors.white : (isDark ? AppColors.textOnDark : AppColors.textPrimary),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─── Featured provider strip card ───
class _FeaturedCard extends StatelessWidget {
  final ProviderModel provider;
  final VoidCallback onTap;

  const _FeaturedCard({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLight, AppColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.secondary,
                  child: Text(provider.user.initials, style: AppTextStyles.titleLarge.copyWith(color: Colors.white)),
                ),
                if (provider.isVerified)
                  Positioned(
                    bottom: 0,
                    right: 0,                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: AppColors.surfaceDark, shape: BoxShape.circle),
                      child: const AppIcon(AppIcons.verified_rounded, size: 14, color: AppColors.secondaryLight),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              provider.user.fullName,
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textOnDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(provider.categoryName, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark)),
            const Spacer(),
            Row(
              children: [
                const AppIcon(AppIcons.star_rounded, size: 14, color: AppColors.star),
                const SizedBox(width: 3),
                Text(
                  provider.averageRating.toStringAsFixed(1),
                  style: AppTextStyles.label.copyWith(color: AppColors.textOnDark, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Text('${provider.completedJobs} jobs', style: AppTextStyles.caption.copyWith(color: AppColors.textMutedDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── 2-column provider grid card ───
class _GridProviderCard extends StatelessWidget {
  final ProviderModel provider;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;
  final VoidCallback onBook;

  const _GridProviderCard({
    required this.provider,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
          boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover with seal + favorite
            Stack(
              children: [
                SizedBox(
                  height: 72,
                  width: double.infinity,
                  child: provider.portfolioImages.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: provider.portfolioImages.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const ShimmerPlaceholder(height: 72),
                        )
                      : Container(color: AppColors.primary),
                ),
                Container(
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
                      child: AppIcon(
                        isFavorite ? AppIcons.favorite_rounded : AppIcons.favorite_border_rounded,
                        size: 15,
                        color: isFavorite ? AppColors.error : Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: 8,
                  child: VerificationSeal(
                    status: provider.verificationStatus,
                    size: 34,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          provider.user.fullName,
                          style: AppTextStyles.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (provider.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 3),
                          child: AppIcon(AppIcons.verified_rounded, size: 15, color: AppColors.secondary),
                        ),
                    ],
                  ),
                  Text(provider.categoryName, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const AppIcon(AppIcons.star_rounded, size: 13, color: AppColors.star),
                      const SizedBox(width: 3),
                      Text(provider.averageRating.toStringAsFixed(1), style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 7),
                      const AppIcon(AppIcons.work_outline_rounded, size: 12, color: AppColors.neutral300),
                      const SizedBox(width: 2),
                      Text('${provider.completedJobs}', style: AppTextStyles.bodySmall),
                      const SizedBox(width: 7),
                      const AppIcon(AppIcons.timeline_rounded, size: 12, color: AppColors.neutral300),
                      const SizedBox(width: 2),
                      Text('${provider.yearsExperience}y', style: AppTextStyles.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    provider.bio,
                    style: AppTextStyles.bodySmall.copyWith(color: isDark ? AppColors.textMutedDark : AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'From ${Formatters.peso(provider.startingPrice ?? 0)}',
                    style: AppTextStyles.monoMd.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: FilledButton(
                      onPressed: onBook,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AppIcon(AppIcons.calendar_month_rounded, size: 15, color: Colors.white),
                          const SizedBox(width: 5),
                          Text('Book now', style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
