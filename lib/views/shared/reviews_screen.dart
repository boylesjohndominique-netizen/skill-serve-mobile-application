import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/cards/review_card.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/widgets/misc/rating_widget.dart';
import '../../data/mock/mock_data.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../core/constants/app_icons.dart';

/// Full reviews list for a provider — reused from the Provider Profile
/// ("See all") and from the Service Provider's own "Reviews" screen.
class ReviewsScreen extends StatefulWidget {
  final String providerId;
  const ReviewsScreen({super.key, required this.providerId});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<ReviewModel>? _reviews;

  @override
  void initState() {
    super.initState();
    ReviewService().getReviewsForProvider(widget.providerId).then((r) {
      if (mounted) setState(() => _reviews = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = MockData.providers.where((p) => p.id == widget.providerId).isNotEmpty
        ? MockData.providers.firstWhere((p) => p.id == widget.providerId)
        : MockData.providers.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Reviews')),
      body: SafeArea(
        child: _reviews == null
            ? const Padding(padding: EdgeInsets.all(AppSizes.pageHPad), child: ShimmerCardList())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.pageHPad),
                    child: Row(
                      children: [
                        Text(provider.averageRating.toStringAsFixed(1), style: AppTextStyles.displayLarge)
                            .animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                        const SizedBox(width: AppSizes.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RatingWidget(rating: provider.averageRating, size: 16),
                            Text('${provider.reviewCount} reviews', style: AppTextStyles.bodyMedium),
                          ],
                        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _reviews!.isEmpty
                        ? const EmptyState(icon: AppIcons.star_border_rounded, title: 'No reviews yet', message: 'Reviews from clients will appear here.')
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad).copyWith(bottom: AppSizes.xl),
                            itemCount: _reviews!.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                            itemBuilder: (context, i) => ReviewCard(review: _reviews![i])
                                .animate()
                                .fadeIn(delay: Duration(milliseconds: 150 + i.clamp(0, 8) * 60), duration: 350.ms)
                                .slideY(begin: 0.06, end: 0),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
