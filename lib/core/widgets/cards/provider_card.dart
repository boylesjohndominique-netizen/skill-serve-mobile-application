import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_animations.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../../models/provider_model.dart';
import '../misc/rating_widget.dart';
import '../feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// Provider summary card — used in Browse Services, Search results, and
/// Favorites. Shows the platform's verification seal when applicable.
///
/// Features soft shadow, press-scale micro-animation, animated favorite
/// heart toggle, and dark-mode-aware colors.
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    child: CachedNetworkImage(
                      imageUrl: widget.provider.portfolioImages.isNotEmpty
                          ? widget.provider.portfolioImages.first
                          : 'https://picsum.photos/seed/${widget.provider.id}/200/200',
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const ShimmerPlaceholder(width: 68, height: 68),
                    ),
                  ),
                  if (widget.provider.isVerified)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: surfaceColor, shape: BoxShape.circle),
                        child: const AppIcon(AppIcons.verified_rounded, size: 16, color: AppColors.secondary),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(widget.provider.user.fullName, style: AppTextStyles.titleMedium, overflow: TextOverflow.ellipsis),
                        ),
                        GestureDetector(
                          onTap: widget.onFavoriteToggle,
                          child: AnimatedBuilder(
                            animation: _heartScale,
                            builder: (context, child) => Transform.scale(
                              scale: _heartScale.value,
                              child: child,
                            ),
                            child: AppIcon(
                              widget.isFavorite ? AppIcons.favorite_rounded : AppIcons.favorite_border_rounded,
                              size: 16,
                              strokeWidth: 1.5,
                              color: widget.isFavorite ? AppColors.error : AppColors.neutral300,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(widget.provider.categoryName, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        RatingWidget(rating: widget.provider.averageRating, reviewCount: widget.provider.reviewCount),
                        const SizedBox(width: 10),
                        const AppIcon(AppIcons.work_outline_rounded, size: 13, color: AppColors.neutral300),
                        const SizedBox(width: 3),
                        Text('${widget.provider.completedJobs} jobs', style: AppTextStyles.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (widget.provider.startingPrice != null)
                      Text(
                        'From ${Formatters.peso(widget.provider.startingPrice!)}',
                        style: AppTextStyles.label.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
