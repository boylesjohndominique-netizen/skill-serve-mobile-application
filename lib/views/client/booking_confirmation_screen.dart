import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../models/booking_model.dart';

/// Success screen shown right after a booking is created.
class BookingConfirmationScreen extends StatelessWidget {
  final BookingModel booking;
  const BookingConfirmationScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 44),
              ).animate().scale(duration: 450.ms, curve: Curves.easeOutBack),
              const SizedBox(height: AppSizes.xl),
              Text('Booking confirmed!', style: AppTextStyles.displayMedium, textAlign: TextAlign.center)
                  .animate()
                  .fadeIn(delay: 150.ms)
                  .slideY(begin: 0.15, end: 0),
              const SizedBox(height: AppSizes.sm),
              Text(
                'We\'ve sent your request to ${booking.providerName}. You\'ll be notified once it\'s accepted.',
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: AppSizes.xxl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Column(
                  children: [
                    _row('Booking ID', booking.id),
                    _row('Service', booking.serviceTitle),
                    _row('Date', Formatters.dateShort(booking.bookingDate)),
                    _row('Time', booking.schedule),
                    _row('Amount', Formatters.peso(booking.amount)),
                  ],
                ),
              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1, end: 0),
              const Spacer(),
              PrimaryButton(label: 'View booking details', onPressed: () => context.go('/booking-details/${booking.id}')),
              const SizedBox(height: AppSizes.sm),
              OutlinedAppButton(label: 'Back to home', onPressed: () => context.go('/client')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(value, style: AppTextStyles.titleMedium),
        ],
      ),
    );
  }
}
