import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/favorites_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/loading_state.dart';
import '../../core/widgets/misc/image_carousel.dart';
import '../../core/widgets/misc/rating_widget.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../models/provider_model.dart';
import '../../services/service_service.dart';

/// Full provider profile for signed-in clients — booking, messaging, and
/// favoriting are all live (vs. the guest preview, which gates these
/// behind a login prompt).
class ProviderProfileScreen extends StatefulWidget {
  final String providerId;
  const ProviderProfileScreen({super.key, required this.providerId});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  ProviderModel? _provider;

  @override
  void initState() {
    super.initState();
    ServiceService().getProviderById(widget.providerId).then((p) {
      if (mounted) setState(() => _provider = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_provider == null) return const Scaffold(body: LoadingState());
    final p = _provider!;
    final favorites = context.watch<FavoritesController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(p.user.fullName),
        actions: [
          IconButton(
            onPressed: () => favorites.toggle(p.id),
            icon: Icon(
              favorites.isFavorite(p.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: favorites.isFavorite(p.id) ? AppColors.error : null,
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
              ImageCarousel(images: p.portfolioImages),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(p.user.fullName, style: AppTextStyles.headlineLarge),
                            if (p.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, size: 18, color: AppColors.secondary),
                            ],
                          ],
                        ),
                        Text(p.categoryName, style: AppTextStyles.bodyLarge),
                      ],
                    ),
                  ),
                  StatusBadge.fromStatus(p.verificationStatus),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  RatingWidget(rating: p.averageRating, reviewCount: p.reviewCount, size: 16),
                  const SizedBox(width: AppSizes.lg),
                  const Icon(Icons.work_outline_rounded, size: 16, color: AppColors.neutral300),
                  const SizedBox(width: 4),
                  Text('${p.completedJobs} jobs', style: AppTextStyles.bodyMedium),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedAppButton(
                      label: 'Message',
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () => context.push('/chat-conversation/${p.id}'),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: OutlinedAppButton(
                      label: 'Portfolio',
                      icon: Icons.photo_library_outlined,
                      onPressed: () => context.push('/portfolio-gallery/${p.id}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xl),
              Text('About', style: AppTextStyles.titleLarge),
              const SizedBox(height: 6),
              Text(p.bio, style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppSizes.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Reviews', style: AppTextStyles.titleLarge),
                  TextButton(
                    onPressed: () => context.push('/reviews/${p.id}'),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('${p.reviewCount} clients rated ${p.user.firstName} an average of ${p.averageRating.toStringAsFixed(1)} stars.',
                  style: AppTextStyles.bodyLarge),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Starting at', style: AppTextStyles.bodySmall),
                      Text(Formatters.peso(p.startingPrice!), style: AppTextStyles.headlineMedium.copyWith(color: AppColors.secondary)),
                    ],
                  ),
                ),
              SizedBox(
                width: 180,
                child: PrimaryButton(
                  label: 'Book now',
                  icon: Icons.calendar_month_rounded,
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
