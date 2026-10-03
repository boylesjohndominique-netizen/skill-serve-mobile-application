import '../../reports/views/report_content_sheet.dart';
import '../../auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../booking/controllers/booking_controller.dart';
import '../../marketplace/controllers/favorites_controller.dart';
import 'favorite_toggle.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons/outlined_app_button.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/review_card.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/misc/image_carousel.dart';
import '../../../core/widgets/misc/rating_widget.dart';
import '../../../core/widgets/misc/verification_seal.dart';
import '../../provider/models/badge_model.dart';
import '../../marketplace/models/provider_model.dart';
import '../../reviews/models/review_model.dart';
import '../../marketplace/models/service_model.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../marketplace/services/service_service.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// Full public provider profile for signed-in clients — the mobile mirror of
/// the admin Marketplace Preview → Profile tab.
class ProviderProfileScreen extends StatefulWidget {
  final String providerId;
  const ProviderProfileScreen({super.key, required this.providerId});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  /// Opens the conversation for this provider.
  ///
  /// Messaging is booking-scoped, so there has to be a booking to talk on. The
  /// newest booking with this provider carries the thread; without one there is
  /// nothing to message about yet, and saying so beats opening an empty screen.
  Future<void> _messageProvider(ProviderModel provider) async {
    final bookings = context.read<BookingController>();
    if (bookings.bookings.isEmpty) {
      await bookings.loadClientBookings();
    }
    if (!mounted) return;

    final withProvider = bookings.bookings
        .where((booking) => booking.providerId == provider.id)
        .toList()
      ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

    if (withProvider.isEmpty) {
      AppSnackbar.error(
        context,
        'Messaging opens once you book ${provider.user.fullName.isEmpty ? 'this provider' : provider.user.fullName}.',
      );
      return;
    }

    context.push('/chat-conversation/${withProvider.first.id}');
  }

  ProviderModel? _provider;
  List<ServiceModel> _services = [];
  List<ReviewModel> _reviews = [];
  List<BadgeModel> _badges = [];
  bool _loaded = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ServiceService();
    if (_failed) setState(() => _failed = false);
    // The provider detail already includes its public services and reviews.
    final ProviderModel provider;
    try {
      provider = await service.getProviderById(widget.providerId);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) return;
    setState(() {
      _provider = provider;
      _services = provider.services;
      _reviews = provider.reviews;
      // Badges come back on the profile payload, so no second request.
      _badges = provider.badges.where((b) => b.earned).toList();
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorState(message: 'Unable to load this provider.', onRetry: _load),
      );
    }
    if (!_loaded || _provider == null) return const Scaffold(body: LoadingState());
    final p = _provider!;
    final favorites = context.watch<FavoritesController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(p.user.fullName),
        actions: [
          IconButton(
            onPressed: () => toggleFavorite(context, p),
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
                              AppIcon(AppIcons.verified_rounded, size: 18, color: context.accentInk),
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
                  AppIcon(AppIcons.work_outline_rounded, size: 16, color: context.textMutedColor),
                  const SizedBox(width: 4),
                  Text('${p.completedJobs} jobs', style: AppTextStyles.bodyMedium),
                  const SizedBox(width: AppSizes.lg),
                  AppIcon(AppIcons.timeline_rounded, size: 16, color: context.textMutedColor),
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
                      onPressed: () => _messageProvider(p),
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

              // ── Verification status ──
              const SizedBox(height: AppSizes.lg),
              _VerificationNotice(provider: p)
                  .animate().fadeIn(delay: 300.ms, duration: 300.ms),

              // ── About ──
              const SizedBox(height: AppSizes.xl),
              const SectionHeaderLocal(title: 'About')
                  .animate().fadeIn(delay: 320.ms, duration: 300.ms),
              const SizedBox(height: 6),
              Text(
                p.bio.isEmpty ? 'This provider has not written an introduction yet.' : p.bio,
                style: AppTextStyles.bodyLarge,
              ).animate().fadeIn(delay: 370.ms, duration: 300.ms),

              // ── Skills ──
              if (p.skills.isNotEmpty) ...[
                const SizedBox(height: AppSizes.xl),
                const SectionHeaderLocal(title: 'Skills')
                    .animate().fadeIn(delay: 380.ms, duration: 300.ms),
                const SizedBox(height: AppSizes.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final skill in p.skills) _SkillChip(label: skill),
                  ],
                ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
              ],

              // ── Recognition: administrator badges and featured status ──
              if (_badges.isNotEmpty || p.isFeatured) ...[
                const SizedBox(height: AppSizes.xl),
                const SectionHeaderLocal(title: 'Recognition')
                    .animate().fadeIn(delay: 390.ms, duration: 300.ms),
                const SizedBox(height: AppSizes.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (p.isFeatured)
                      _RecognitionChip(
                        label: 'Featured provider',
                        icon: AppIcons.workspace_premium_rounded,
                        color: context.accentInk,
                      ),
                    for (var i = 0; i < _badges.length; i++)
                      _BadgeChip(badge: _badges[i])
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: 420 + i * 60), duration: 300.ms)
                          .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                  ],
                ),
              ],

              // ── Availability ──
              const SizedBox(height: AppSizes.xl),
              const SectionHeaderLocal(title: 'Availability')
                  .animate().fadeIn(delay: 430.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.md),
              _AvailabilityPanel(provider: p)
                  .animate().fadeIn(delay: 450.ms, duration: 300.ms),

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
                    child: ReviewCard(
                      review: _reviews[i],
                      onReport: _reportAction(context, _reviews[i]),
                    )
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
                      Text(Formatters.peso(p.startingPrice!), style: AppTextStyles.monoLg.copyWith(color: context.accentInk)),
                    ],
                  ),
                ),
              SizedBox(
                width: 190,
                child: PrimaryButton(
                  label: p.isAcceptingBookings ? 'Book ${p.user.firstName}' : 'Not taking bookings',
                  icon: AppIcons.calendar_month_rounded,
                  // The API refuses bookings for a paused provider, so the
                  // button reflects that instead of failing on submit.
                  onPressed: p.isAcceptingBookings
                      ? () => context.push('/booking-form/${p.id}')
                      : null,
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

/// States whether the provider has completed SkillServe's verification, and
/// when it was granted.
class _VerificationNotice extends StatelessWidget {
  final ProviderModel provider;
  const _VerificationNotice({required this.provider});

  @override
  Widget build(BuildContext context) {
    final verified = provider.isVerified;
    final color = verified ? AppColors.success : context.accentInk;
    final verifiedAt = provider.verifiedAt;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          AppIcon(
            verified ? AppIcons.verified_user_rounded : AppIcons.hourglass_top_rounded,
            size: 20,
            color: color,
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verified ? 'Verified provider' : 'Verification in progress',
                  style: AppTextStyles.titleMedium.copyWith(color: color),
                ),
                Text(
                  verified
                      ? (verifiedAt == null
                          ? 'Identity and credentials checked by the SkillServe team.'
                          : 'Checked by the SkillServe team on ${Formatters.dateShort(verifiedAt)}.')
                      : 'This provider has not completed SkillServe\'s verification yet.',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The provider's published weekly hours, and whether they are taking new
/// bookings at all.
class _AvailabilityPanel extends StatelessWidget {
  final ProviderModel provider;
  const _AvailabilityPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final schedule = provider.availability;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                provider.isAcceptingBookings ? AppIcons.event_available_rounded : AppIcons.event_busy_rounded,
                size: 18,
                color: provider.isAcceptingBookings ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  provider.isAcceptingBookings
                      ? 'Accepting new bookings'
                      : 'Not accepting new bookings right now',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: provider.isAcceptingBookings ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          if (schedule.isEmpty)
            Text(
              'No set hours — send a message to agree on a time.',
              style: AppTextStyles.bodyMedium,
            )
          else
            for (final window in schedule)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(window.dayName, style: AppTextStyles.bodyMedium),
                    ),
                    Text(
                      window.label,
                      style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Text(label, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class _RecognitionChip extends StatelessWidget {
  final String label;
  final AppIconData icon;
  final Color color;

  const _RecognitionChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.label.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
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
                    AppIcon(AppIcons.schedule_rounded, size: 13, color: context.textMutedColor),
                    const SizedBox(width: 4),
                    Text(service.duration, style: AppTextStyles.bodySmall),
                    const SizedBox(width: 12),
                    Text(
                      // Custom-priced work is quoted by the provider, so no
                      // amount is shown for it.
                      service.isQuoteOnly ? 'On quote' : Formatters.peso(service.price),
                      style: AppTextStyles.monoMd.copyWith(color: context.accentInk, fontWeight: FontWeight.w700),
                    ),
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
              child: Text('Book', style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

/// A report action for [review], or null when there should be none: a guest
/// cannot report, and nobody reports their own review — they edit it.
VoidCallback? _reportAction(BuildContext context, ReviewModel review) {
  final auth = context.read<AuthController>();
  final me = auth.currentUser?.id;
  if (me == null || review.reviewerId == me) return null;
  return () => showReportContentSheet(
        context,
        reviewId: review.id,
        title: 'Report this review',
      );
}
