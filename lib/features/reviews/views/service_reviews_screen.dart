import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/cards/review_card.dart';
import '../../../core/widgets/cards/section_card.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/rating_summary.dart';
import '../../reports/views/report_content_sheet.dart';
import '../controllers/service_reviews_controller.dart';

/// Every published review of one service: the rating summary (tap a star
/// row to see only those reviews) and the reviews, loaded as you scroll.
/// Live — a review another customer posts appears while it is open.
class ServiceReviewsScreen extends StatelessWidget {
  final String serviceId;

  /// Shown in the title when the caller knows it.
  final String? serviceTitle;

  const ServiceReviewsScreen({super.key, required this.serviceId, this.serviceTitle});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ServiceReviewsController(serviceId: serviceId)..load(),
      child: _ServiceReviewsView(serviceTitle: serviceTitle),
    );
  }
}

class _ServiceReviewsView extends StatelessWidget {
  final String? serviceTitle;
  const _ServiceReviewsView({this.serviceTitle});

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ServiceReviewsController>();

    Widget body;
    if (!reviews.hasLoaded && reviews.error != null) {
      body = ErrorState(message: reviews.error!, onRetry: reviews.load);
    } else if (!reviews.hasLoaded) {
      body = const Padding(padding: EdgeInsets.all(AppSizes.pageHPad), child: ShimmerCardList(count: 4, itemHeight: 110));
    } else {
      body = NotificationListener<ScrollNotification>(
        // Load the next page as the list nears its end.
        onNotification: (n) {
          if (n.metrics.extentAfter < 400) reviews.loadMore();
          return false;
        },
        child: RefreshIndicator(
          color: context.accentInk,
          onRefresh: reviews.load,
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.pageHPad),
            children: [
              SectionCard(
                title: 'Rating',
                subtitle: reviews.rating == null ? 'Tap a star row to filter' : 'Showing ${reviews.rating}-star reviews',
                child: RatingSummary(
                  average: reviews.average,
                  total: reviews.total,
                  breakdown: reviews.breakdown,
                  selected: reviews.rating,
                  onSelect: reviews.filter,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              if (reviews.isLoading)
                const ShimmerCardList(count: 3, itemHeight: 110)
              else if (reviews.reviews.isEmpty)
                EmptyState(
                  icon: AppIcons.reviews_outlined,
                  title: reviews.rating == null ? 'No reviews yet' : 'No ${reviews.rating}-star reviews',
                  message: reviews.rating == null
                      ? 'Customers can review this service once a booking is completed.'
                      : 'Try another star rating, or show all reviews.',
                  actionLabel: reviews.rating == null ? null : 'Show all reviews',
                  onAction: reviews.rating == null ? null : () => reviews.filter(null),
                )
              else
                for (var i = 0; i < reviews.reviews.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.md),
                    child: ReviewCard(
                      review: reviews.reviews[i],
                      onReport: reviewReportAction(context, reviews.reviews[i]),
                    ).animate().fadeIn(delay: Duration(milliseconds: (i % 10) * 40), duration: 300.ms),
                  ),
              if (reviews.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.all(AppSizes.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          serviceTitle == null || serviceTitle!.isEmpty ? 'Reviews' : 'Reviews · $serviceTitle',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(child: body),
    );
  }
}

/// The reviews section of Service Details: the summary and the latest few,
/// with a link to all of them.
class ServiceReviewsPreview extends StatelessWidget {
  final String serviceId;
  final String serviceTitle;
  const ServiceReviewsPreview({super.key, required this.serviceId, required this.serviceTitle});

  static const _shown = 3;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ServiceReviewsController(serviceId: serviceId, pageSize: _shown)..load(),
      child: Builder(builder: (context) {
        final reviews = context.watch<ServiceReviewsController>();
        if (!reviews.hasLoaded) {
          return reviews.error == null
              ? const ShimmerCardList(count: 1, itemHeight: 120)
              : const SizedBox.shrink();
        }

        return SectionCard(
          title: 'Reviews',
          subtitle: reviews.total == 0 ? null : 'What customers say about this service',
          action: reviews.total > _shown
              ? TextButton(
                  onPressed: () => context.push(
                    '/service-reviews/$serviceId?title=${Uri.encodeQueryComponent(serviceTitle)}',
                  ),
                  child: Text('See all ${reviews.total}'),
                )
              : null,
          child: reviews.total == 0
              ? Text(
                  'No reviews yet — customers can review this service once a booking is completed.',
                  style: AppTextStyles.bodySmall,
                )
              : Column(
                  children: [
                    RatingSummary(average: reviews.average, total: reviews.total, breakdown: reviews.breakdown),
                    const SizedBox(height: AppSizes.md),
                    for (final review in reviews.reviews.take(_shown))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: ReviewCard(review: review, onReport: reviewReportAction(context, review)),
                      ),
                  ],
                ),
        );
      }),
    );
  }
}
