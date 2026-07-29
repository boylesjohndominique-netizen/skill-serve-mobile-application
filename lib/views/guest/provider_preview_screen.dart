import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSizes.xl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
          boxShadow: AppSizes.shadowLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: AppSizes.lg),
              decoration: BoxDecoration(color: AppColors.neutral200, borderRadius: BorderRadius.circular(2)),
            ),
            const Icon(Icons.lock_outline_rounded, size: 36, color: AppColors.secondary)
                .animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
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
              ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  RatingWidget(rating: p.averageRating, reviewCount: p.reviewCount, size: 16),
                  const SizedBox(width: AppSizes.lg),
                  const Icon(Icons.work_outline_rounded, size: 16, color: AppColors.neutral300),
                  const SizedBox(width: 4),
                  Text('${p.completedJobs} jobs completed', style: AppTextStyles.bodyMedium),
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.xl),
              Text('About', style: AppTextStyles.titleLarge)
                  .animate().fadeIn(delay: 280.ms, duration: 300.ms),
              const SizedBox(height: 6),
              Text(p.bio, style: AppTextStyles.bodyLarge)
                  .animate().fadeIn(delay: 330.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.xl),
              Text('Experience', style: AppTextStyles.titleLarge)
                  .animate().fadeIn(delay: 380.ms, duration: 300.ms),
              const SizedBox(height: 6),
              Text('${p.yearsExperience} years in ${p.categoryName.toLowerCase()} services', style: AppTextStyles.bodyLarge)
                  .animate().fadeIn(delay: 430.ms, duration: 300.ms),
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
