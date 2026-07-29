import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/loading_state.dart';
import '../../core/widgets/misc/image_carousel.dart';
import '../../core/widgets/misc/rating_widget.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../models/provider_model.dart';
import '../../services/service_service.dart';

/// Read-only provider profile for guests. Any booking action routes to
/// Login instead of the booking form.
class ProviderPreviewScreen extends StatefulWidget {
  final String providerId;
  const ProviderPreviewScreen({super.key, required this.providerId});

  @override
  State<ProviderPreviewScreen> createState() => _ProviderPreviewScreenState();
}

class _ProviderPreviewScreenState extends State<ProviderPreviewScreen> {
  ProviderModel? _provider;

  @override
  void initState() {
    super.initState();
    ServiceService().getProviderById(widget.providerId).then((p) {
      if (mounted) setState(() => _provider = p);
    });
  }

  void _promptLogin() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.xl),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 36, color: AppColors.secondary),
            const SizedBox(height: AppSizes.md),
            Text('Log in to book this provider', style: AppTextStyles.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              'Create a free account or log in to schedule a booking and message providers directly.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xl),
            PrimaryButton(label: 'Log in', onPressed: () => context.go('/login')),
            const SizedBox(height: AppSizes.sm),
            TextButton(onPressed: () => context.go('/register'), child: const Text('Create an account instead')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_provider == null) return const Scaffold(body: LoadingState());
    final p = _provider!;

    return Scaffold(
      appBar: AppBar(title: Text(p.user.fullName)),
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
                  Text('${p.completedJobs} jobs completed', style: AppTextStyles.bodyMedium),
                ],
              ),
              const SizedBox(height: AppSizes.xl),
              Text('About', style: AppTextStyles.titleLarge),
              const SizedBox(height: 6),
              Text(p.bio, style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppSizes.xl),
              Text('Experience', style: AppTextStyles.titleLarge),
              const SizedBox(height: 6),
              Text('${p.yearsExperience} years in ${p.categoryName.toLowerCase()} services', style: AppTextStyles.bodyLarge),
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
                child: PrimaryButton(label: 'Book now', icon: Icons.calendar_month_rounded, onPressed: _promptLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
