import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/inputs/app_text_field.dart';
import '../../data/mock/mock_data.dart';
import '../../models/booking_model.dart';
import '../../services/review_service.dart';

/// Write a review for a completed booking (one review per completed booking).
class WriteReviewScreen extends StatefulWidget {
  final String bookingId;
  const WriteReviewScreen({super.key, required this.bookingId});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;

  late final BookingModel _booking;

  @override
  void initState() {
    super.initState();
    final all = [...MockData.bookingsForClient, ...MockData.bookingsForProvider];
    _booking = all.where((b) => b.id == widget.bookingId).isNotEmpty
        ? all.firstWhere((b) => b.id == widget.bookingId)
        : MockData.bookingsForClient.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave a Review')),
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
                'Your review for "${_booking.serviceTitle}" with ${_booking.providerName} helps other clients choose trusted pros.',
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
                                child: Icon(
                                  i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  size: 40,
                                  color: i <= _rating ? AppColors.star : AppColors.neutral200,
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
                        style: AppTextStyles.label.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700),
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
                prefixIcon: Icons.edit_outlined,
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
                  label: 'Submit review',
                  icon: Icons.send_rounded,
                  isLoading: _submitting,
                  onPressed: _rating == 0
                      ? null
                      : () async {
                          setState(() => _submitting = true);
                          await ReviewService().submitReview(
                            bookingId: widget.bookingId,
                            rating: _rating.toDouble(),
                            comment: _commentController.text.trim(),
                          );
                          if (!mounted) return;
                          setState(() => _submitting = false);
                          if (!context.mounted) return;
                          AppSnackbar.success(context, 'Thanks! Your review has been posted.');
                          context.pop();
                        },
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
