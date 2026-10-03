import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/review_controller.dart';
import '../models/review_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/rating_widget.dart';
import '../../../core/widgets/misc/status_badge.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// The reviews this customer has written, each one editable.
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewController>().loadMyReviews();
    });
  }

  Future<void> _reload() => context.read<ReviewController>().loadMyReviews();

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewController>();
    final failed = reviews.errorMessage != null && reviews.myReviews.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('My Reviews')),
      body: SafeArea(
        child: reviews.isLoading
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pageHPad),
                child: ShimmerCardList(itemHeight: 120),
              )
            : failed
                ? ErrorState(message: reviews.errorMessage!, onRetry: _reload)
                : RefreshIndicator(
                    onRefresh: _reload,
                    child: reviews.myReviews.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.only(top: AppSizes.xxl),
                            children: const [
                              EmptyState(
                                icon: AppIcons.star_outline_rounded,
                                title: 'No reviews yet',
                                message:
                                    'After a job is completed you can rate it, and your reviews will be listed here.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(AppSizes.pageHPad),
                            itemCount: reviews.myReviews.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                            itemBuilder: (context, i) => _MyReviewCard(review: reviews.myReviews[i])
                                .animate()
                                .fadeIn(
                                    delay: Duration(milliseconds: i.clamp(0, 8) * 60),
                                    duration: 350.ms)
                                .slideY(begin: 0.06, end: 0),
                          ),
                  ),
      ),
    );
  }
}

class _MyReviewCard extends StatelessWidget {
  final ReviewModel review;
  const _MyReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
        boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.serviceTitle.isEmpty ? 'Reviewed service' : review.serviceTitle,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // A hidden or removed review is still the author's, so say so.
              if (!review.isPublished) ...[
                const SizedBox(width: AppSizes.sm),
                StatusBadge.fromStatus(review.status),
              ],
            ],
          ),
          if (review.providerName.isNotEmpty)
            Text(review.providerName, style: AppTextStyles.bodySmall),
          const SizedBox(height: AppSizes.sm),
          RatingWidget(rating: review.rating, size: 15),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            Text(review.comment, style: AppTextStyles.bodyMedium),
          ],
          Divider(height: AppSizes.lg, color: lineColor),
          Row(
            children: [
              Text(
                '${Formatters.relative(review.createdAt)}${review.wasEdited ? ' · edited' : ''}',
                style: AppTextStyles.bodySmall,
              ),
              const Spacer(),
              if (review.bookingId.isNotEmpty)
                TextButton.icon(
                  onPressed: () => context.push('/write-review/${review.bookingId}'),
                  icon: AppIcon(AppIcons.edit_outlined,
                      size: 15, color: context.accentInk),
                  label: Text('Edit',
                      style: AppTextStyles.label.copyWith(color: context.accentInk)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
