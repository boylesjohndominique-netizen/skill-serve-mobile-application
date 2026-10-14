import 'package:flutter/material.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../../features/marketplace/models/provider_model.dart';
import '../misc/app_avatar.dart';
import '../misc/on_job_badge.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// Provider summary card — Home, Explore, Browse Services and Favorites.
///
/// One clean row: the provider's own photo (or initials) with a verified
/// tick, their name, category and area, rating and finished bookings, and the
/// lowest price with the favorite toggle. Never a stock photo: a picture next
/// to a name reads as that person or their work.
class ProviderCard extends StatefulWidget {
  final ProviderModel provider;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const ProviderCard({
    super.key,
    required this.provider,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  State<ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<ProviderCard> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  // Heart pop animation
  late final AnimationController _heartController = AnimationController(
    vsync: this,
    duration: AppAnimations.md,
  );
  late final Animation<double> _heartScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
  ]).animate(CurvedAnimation(parent: _heartController, curve: AppAnimations.defaultCurve));

  @override
  void didUpdateWidget(ProviderCard old) {
    super.didUpdateWidget(old);
    if (old.isFavorite != widget.isFavorite) {
      _heartController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? AppAnimations.cardPressScale : 1.0,
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
            boxShadow: _pressed
                ? AppSizes.shadowFor(context, level: ShadowLevel.sm)
                : AppSizes.shadowFor(context, level: ShadowLevel.md),
          ),
          child: Row(
            children: [
              _Avatar(provider: widget.provider, ringColor: surfaceColor),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.provider.user.fullName,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (widget.provider.categoryName.isNotEmpty) widget.provider.categoryName,
                        if (widget.provider.location.isNotEmpty) widget.provider.location,
                      ].join(' • '),
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        AppIcon(AppIcons.star_rounded, size: 14, color: context.starColor),
                        const SizedBox(width: 3),
                        Text(
                          widget.provider.reviewCount == 0
                              ? 'New'
                              : '${widget.provider.averageRating.toStringAsFixed(1)} (${widget.provider.reviewCount})',
                          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(' • ', style: AppTextStyles.bodySmall),
                        Flexible(
                          child: Text(
                            '${widget.provider.completedBookings} '
                            '${widget.provider.completedBookings == 1 ? 'booking' : 'bookings'} done',
                            style: AppTextStyles.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (widget.provider.onJobNow) ...[
                      const SizedBox(height: 4),
                      const OnJobBadge(),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Semantics(
                    button: true,
                    label: widget.isFavorite ? 'Remove from favorites' : 'Add to favorites',
                    child: GestureDetector(
                      onTap: widget.onFavoriteToggle,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: AnimatedBuilder(
                          animation: _heartScale,
                          builder: (context, child) => Transform.scale(scale: _heartScale.value, child: child),
                          child: AppIcon(
                            widget.isFavorite ? AppIcons.favorite_rounded : AppIcons.favorite_border_rounded,
                            size: 18,
                            strokeWidth: 1.5,
                            color: widget.isFavorite ? AppColors.error : context.textMutedColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.provider.startingPrice != null) ...[
                    const SizedBox(height: AppSizes.sm),
                    Text('From', style: AppTextStyles.caption),
                    Text(
                      Formatters.peso(widget.provider.startingPrice!),
                      style: AppTextStyles.label.copyWith(color: context.accentInk, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The provider's photo, or their initials, with a verified tick.
class _Avatar extends StatelessWidget {
  final ProviderModel provider;
  final Color ringColor;

  const _Avatar({required this.provider, required this.ringColor});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppAvatar(
          initials: provider.user.initials,
          photoUrl: provider.user.profilePicture,
          radius: 26,
          backgroundColor: context.accentSoftColor,
          foregroundColor: context.onAccentSoftColor,
        ),
        if (provider.isVerified)
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: ringColor, shape: BoxShape.circle),
              child: AppIcon(AppIcons.verified_rounded, size: 15, color: context.accentInk),
            ),
          ),
      ],
    );
  }
}
