import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/buttons/outlined_app_button.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../booking/models/booking_model.dart';
import '../../booking/services/booking_service.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../controllers/review_controller.dart';
import '../models/review_model.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// Write or edit the review for a completed booking (one per booking).
class WriteReviewScreen extends StatefulWidget {
  final String bookingId;
  const WriteReviewScreen({super.key, required this.bookingId});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;

  BookingModel? _booking;

  /// The review already on this booking, when there is one — the screen then
  /// edits it instead of posting a second.
  ReviewModel? _existing;
  bool _loading = true;
  String? _error;

  bool get _isEditing => _existing != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final reviews = context.read<ReviewController>();
    try {
      final bookings = await BookingService().getClientBookings();
      // The review history tells us whether this booking is already reviewed.
      if (reviews.myReviews.isEmpty) await reviews.loadMyReviews();
      if (!mounted) return;

      final match = bookings.where((b) => b.id == widget.bookingId);
      final existing = reviews.reviewForBooking(widget.bookingId);

      setState(() {
        _booking = match.isNotEmpty ? match.first : null;
        _existing = existing;
        if (existing != null) {
          _rating = existing.rating.round();
          _commentController.text = existing.comment;
        }
        _error = match.isEmpty ? 'This booking could not be found.' : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e, 'Unable to open this review.');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final reviews = context.read<ReviewController>();
    final saved = _isEditing
        ? await reviews.update(
            reviewId: _existing!.id,
            rating: _rating.toDouble(),
            comment: _commentController.text,
          )
        : await reviews.submit(
            bookingId: widget.bookingId,
            rating: _rating.toDouble(),
            comment: _commentController.text,
          );
    if (!mounted) return;

    if (saved == null) {
      AppSnackbar.error(context, reviews.errorMessage ?? 'Unable to save your review.');
      return;
    }
    AppSnackbar.success(
        context,
        _isEditing
            ? 'Your review has been updated.'
            : 'Thanks! Your review has been posted.');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingState());

    final booking = _booking;
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review')),
        body: SafeArea(
          child: ErrorState(
            message: _error ?? 'This booking could not be found.',
            onRetry: _load,
          ),
        ),
      );
    }

    final reviews = context.watch<ReviewController>();

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Your Review' : 'Leave a Review')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How was your experience?', style: AppTextStyles.displayMedium)
                  .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: 6),
              Text(
                'Your review for "${booking.serviceTitle}" with ${booking.providerName} helps other clients choose trusted pros.',
                style: AppTextStyles.bodyLarge,
              ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
              const SizedBox(height: AppSizes.xl),

              // Star input
              Center(
                child: Column(
                  children: [
                    Text('Tap to rate', style: AppTextStyles.titleLarge)
                        .animate().fadeIn(delay: 180.ms, duration: 300.ms),
                    const SizedBox(height: AppSizes.md),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 1; i <= 5; i++)
                          GestureDetector(
                            onTap: () => setState(() => _rating = i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: AnimatedScale(
                                scale: i <= _rating ? 1.1 : 1.0,
                                duration: AppAnimations.md,
                                curve: AppAnimations.springCurve,
                                child: AppIcon(
                                  i <= _rating ? AppIcons.star_rounded : AppIcons.star_outline_rounded,
                                  size: 40,
                                  color: i <= _rating ? context.starColor : AppColors.neutral200,
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: Duration(milliseconds: 220 + i * 40), duration: 300.ms)
                              .scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack),
                      ],
                    ),
                    const SizedBox(height: AppSizes.sm),
                    AnimatedSwitcher(
                      duration: AppAnimations.md,
                      child: Text(
                        _rating == 0 ? 'No rating yet' : _ratingLabel(_rating),
                        key: ValueKey(_rating),
                        style: AppTextStyles.label.copyWith(color: context.accentInk, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),

              AppTextField(
                label: 'Your review',
                hint: 'Share what went well (or what could improve)…',
                controller: _commentController,
                maxLines: 5,
                maxLength: 2000,
                prefixIcon: AppIcons.edit_outlined,
              ).animate().fadeIn(delay: 450.ms, duration: 350.ms).slideY(begin: 0.05, end: 0),
              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Row(
            children: [
              Expanded(
                child: OutlinedAppButton(
                  label: 'Cancel',
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: _isEditing ? 'Save changes' : 'Submit review',
                  icon: AppIcons.send_rounded,
                  isLoading: reviews.isSaving,
                  onPressed: _rating == 0 || reviews.isSaving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }
}
