import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/favorites_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/cards/review_card.dart';
import '../../core/widgets/feedback/loading_state.dart';
import '../../core/widgets/misc/image_carousel.dart';
import '../../core/widgets/misc/rating_widget.dart';
import '../../core/widgets/misc/verification_seal.dart';
import '../../models/badge_model.dart';
import '../../models/provider_model.dart';
import '../../models/review_model.dart';
import '../../models/service_model.dart';
import '../../services/review_service.dart';
import '../../services/service_service.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

/// Full public provider profile for signed-in clients — the mobile mirror of
/// the admin Marketplace Preview → Profile tab.
class ProviderProfileScreen extends StatefulWidget {
  final String providerId;
  const ProviderProfileScreen({super.key, required this.providerId});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  ProviderModel? _provider;
  List<ServiceModel> _services = [];
  List<ReviewModel> _reviews = [];
  List<BadgeModel> _badges = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ServiceService();
    final provider = await service.getProviderById(widget.providerId);
    final results = await Future.wait([
      service.getServicesForProvider(provider.id),
      ReviewService().getReviewsForProvider(provider.id),
      service.getProviderBadges(provider.id),
    ]);
    if (!mounted) return;
    setState(() {
      _provider = provider;
      _services = results[0] as List<ServiceModel>;
      _reviews = results[1] as List<ReviewModel>;
      _badges = (results[2] as List<BadgeModel>).where((b) => b.earned).toList();
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _provider == null) return const Scaffold(body: LoadingState());
    final p = _provider!;
    final favorites = context.watch<FavoritesController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(p.user.fullName),
        actions: [
          IconButton(
            onPressed: () => favorites.toggle(p.id),
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: AppIcon(
                favorites.isFavorite(p.id) ? AppIcons.favorite_rounded : AppIcons.favorite_border_rounded,
                key: ValueKey(favorites.isFavorite(p.id)),
                color: favorites.isFavorite(p.id) ? AppColors.error : null,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImageCarousel(images: p.portfolioImages)
                  .animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(p.user.fullName, style: AppTextStyles.headlineLarge, overflow: TextOverflow.ellipsis),
                            ),
                            if (p.isVerified) ...[
                              const SizedBox(width: 6),
                              const AppIcon(AppIcons.verified_rounded, size: 18, color: AppColors.secondary),
                            ],
                          ],
                        ),
                        Text(p.categoryName, style: AppTextStyles.bodyLarge),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  VerificationSeal(status: p.verificationStatus, size: 44, showLabel: true),
                ],
              ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  RatingWidget(rating: p.averageRating, reviewCount: p.reviewCount, size: 16),
                  const SizedBox(width: AppSizes.lg),
                  const AppIcon(AppIcons.work_outline_rounded, size: 16, color: AppColors.neutral300),
                  const SizedBox(width: 4),
                  Text('${p.completedJobs} jobs', style: AppTextStyles.bodyMedium),
                  const SizedBox(width: AppSizes.lg),
                  const AppIcon(AppIcons.timeline_rounded, size: 16, color: AppColors.neutral300),
                  const SizedBox(width: 4),
                  Text('${p.yearsExperience} yrs', style: AppTextStyles.bodyMedium),
                ],
              ).animate().fadeIn(delay: 180.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedAppButton(
                      label: 'Message',
                      icon: AppIcons.chat_bubble_outline_rounded,
                      onPressed: () => context.push('/chat-conversation/${p.id}'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: OutlinedAppButton(
                      label: 'Portfolio',
                      icon: AppIcons.photo_library_outlined,
                      onPressed: () => context.push('/portfolio-gallery/${p.id}'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 260.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),

              // ── About ──
              const SizedBox(height: AppSizes.xl),
              const SectionHeaderLocal(title: 'About')
                  .animate().fadeIn(delay: 320.ms, duration: 300.ms),
              const SizedBox(height: 6),
              Text(p.bio, style: AppTextStyles.bodyLarge)
                  .animate().fadeIn(delay: 370.ms, duration: 300.ms),

              // ── Recognition badges ──
              if (_badges.isNotEmpty) ...[
                const SizedBox(height: AppSizes.xl),
                const SectionHeaderLocal(title: 'Recognition')
                    .animate().fadeIn(delay: 390.ms, duration: 300.ms),
                const SizedBox(height: AppSizes.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _badges.length; i++)
                      _BadgeChip(badge: _badges[i])
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 420 + i * 60), duration: 300.ms)
                          .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                  ],
                ),
              ],

              // ── Services ──
              const SizedBox(height: AppSizes.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionHeaderLocal(title: 'Services')
                      .animate().fadeIn(delay: 460.ms, duration: 300.ms),
                  Text('${_services.length} active', style: AppTextStyles.bodySmall),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              if (_services.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
                  child: Text(
                    '${p.user.firstName} hasn\'t listed services yet — send a message to ask about availability.',
                    style: AppTextStyles.bodyMedium,
                  ),
                )
              else
                for (var i = 0; i < _services.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.sm),
                    child: _ServiceRow(
                      service: _services[i],
                      onBook: () => context.push('/booking-form/${p.id}'),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 480 + i * 60), duration: 350.ms)
                        .slideY(begin: 0.05, end: 0),
                  ),

              // ── Reviews ──
              const SizedBox(height: AppSizes.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionHeaderLocal(title: 'Reviews')
                      .animate().fadeIn(delay: 520.ms, duration: 300.ms),
                  TextButton(
                    onPressed: () => context.push('/reviews/${p.id}'),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_reviews.isEmpty)
                Text('No reviews yet — be the first to book!', style: AppTextStyles.bodyLarge)
                    .animate().fadeIn(delay: 560.ms, duration: 300.ms)
              else
                for (var i = 0; i < _reviews.take(2).length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.md),
                    child: ReviewCard(review: _reviews[i])
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 560 + i * 60), duration: 350.ms)
                        .slideY(begin: 0.05, end: 0),
                  ),
              const SizedBox(height: AppSizes.xxxl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Row(
            children: [
              if (p.startingPrice != null)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Starting at', style: AppTextStyles.bodySmall),
                      Text(Formatters.peso(p.startingPrice!), style: AppTextStyles.monoLg.copyWith(color: AppColors.secondary)),
                    ],
                  ),
                ),
              SizedBox(
                width: 190,
                child: PrimaryButton(
                  label: 'Book ${p.user.firstName}',
                  icon: AppIcons.calendar_month_rounded,
                  onPressed: () => context.push('/booking-form/${p.id}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Local section header (kept private to this screen).
class SectionHeaderLocal extends StatelessWidget {
  final String title;
  const SectionHeaderLocal({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.titleLarge);
  }
}

class _BadgeChip extends StatelessWidget {
  final BadgeModel badge;
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 8),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(color: badge.color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(badge.icon, size: 15, color: badge.color),
          const SizedBox(width: 6),
          Text(
            badge.title,
            style: AppTextStyles.label.copyWith(
              color: badge.color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onBook;
  const _ServiceRow({required this.service, required this.onBook});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5), width: 0.8),
        boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.title, style: AppTextStyles.titleMedium, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const AppIcon(AppIcons.schedule_rounded, size: 13, color: AppColors.neutral300),
                    const SizedBox(width: 4),
                    Text(service.duration, style: AppTextStyles.bodySmall),
                    const SizedBox(width: 12),
                    Text(Formatters.peso(service.price), style: AppTextStyles.monoMd.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),
          SizedBox(
            height: 34,
            child: FilledButton(
              onPressed: onBook,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
              ),
              child: Text('Book', style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
