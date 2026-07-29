import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/booking_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/app_dialog.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/feedback/loading_state.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../data/mock/mock_data.dart';
import '../../models/booking_model.dart';

class BookingDetailsScreen extends StatelessWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final all = [...MockData.bookingsForClient, ...MockData.bookingsForProvider];
    final booking = all.where((b) => b.id == bookingId).isNotEmpty
        ? all.firstWhere((b) => b.id == bookingId)
        : null;

    if (booking == null) return const Scaffold(body: LoadingState());

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${booking.id}', style: AppTextStyles.bodySmall),
                  StatusBadge.fromStatus(booking.status.name),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              Text(booking.serviceTitle, style: AppTextStyles.displayMedium),
              const SizedBox(height: AppSizes.xl),

              _SectionCard(
                title: 'Schedule',
                children: [
                  _detailRow(Icons.calendar_today_rounded, 'Date', Formatters.dateShort(booking.bookingDate)),
                  _detailRow(Icons.access_time_rounded, 'Time', booking.schedule),
                  _detailRow(Icons.location_on_outlined, 'Address', booking.address.isEmpty ? '—' : booking.address),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              _SectionCard(
                title: 'Parties',
                children: [
                  _detailRow(Icons.person_outline_rounded, 'Client', booking.clientName),
                  _detailRow(Icons.handyman_outlined, 'Provider', booking.providerName),
                ],
              ),
              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.lg),
                _SectionCard(title: 'Notes', children: [Text(booking.notes!, style: AppTextStyles.bodyLarge)]),
              ],
              const SizedBox(height: AppSizes.lg),
              Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total amount', style: AppTextStyles.titleMedium),
                    Text(Formatters.peso(booking.amount), style: AppTextStyles.headlineMedium.copyWith(color: AppColors.secondary)),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xxl),
              if (booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed)
                OutlinedAppButton(
                  label: 'Cancel booking',
                  icon: Icons.close_rounded,
                  color: AppColors.error,
                  onPressed: () async {
                    final confirmed = await AppDialog.confirm(
                      context,
                      title: 'Cancel this booking?',
                      message: 'This will notify ${booking.providerName} that the booking is cancelled.',
                      confirmLabel: 'Cancel booking',
                      danger: true,
                    );
                    if (confirmed && context.mounted) {
                      await context.read<BookingController>().cancel(booking.id);
                      if (context.mounted) {
                        AppSnackbar.success(context, 'Booking cancelled.');
                        context.pop();
                      }
                    }
                  },
                ),
              if (booking.status == BookingStatus.completed)
                PrimaryButton(
                  label: 'Leave a review',
                  icon: Icons.star_border_rounded,
                  onPressed: () => context.push('/reviews/${booking.providerId}'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.neutral300),
          const SizedBox(width: AppSizes.sm),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(value, style: AppTextStyles.titleMedium),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleLarge),
          const SizedBox(height: 4),
          ...children,
        ],
      ),
    );
  }
}
