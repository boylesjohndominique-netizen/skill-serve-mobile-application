import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_text_styles.dart';
import '../../utils/formatters.dart';
import '../../../models/booking_model.dart';
import '../misc/status_badge.dart';

/// Booking summary card used in Booking History (client) and
/// Booking Requests / Active / Completed lists (provider).
class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isProviderView;
  final VoidCallback? onTap;

  const BookingCard({super.key, required this.booking, this.isProviderView = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(booking.serviceTitle, style: AppTextStyles.titleMedium, overflow: TextOverflow.ellipsis),
                ),
                StatusBadge.fromStatus(booking.status.name),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isProviderView ? 'Client: ${booking.clientName}' : 'Provider: ${booking.providerName}',
              style: AppTextStyles.bodyMedium,
            ),
            const Divider(height: AppSizes.lg),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.neutral300),
                const SizedBox(width: 6),
                Text(Formatters.dateShort(booking.bookingDate), style: AppTextStyles.bodySmall),
                const SizedBox(width: 14),
                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.neutral300),
                const SizedBox(width: 6),
                Text(booking.schedule, style: AppTextStyles.bodySmall),
                const Spacer(),
                Text(
                  Formatters.peso(booking.amount),
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.secondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
