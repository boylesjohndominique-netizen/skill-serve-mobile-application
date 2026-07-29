import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../controllers/provider_booking_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/app_dialog.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../models/booking_model.dart';

/// Pending booking requests — providers accept or decline before the
/// booking moves to Active Jobs.
class BookingRequestsScreen extends StatefulWidget {
  final bool embedded;
  const BookingRequestsScreen({super.key, this.embedded = false});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderBookingController>().loadProviderBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderBookingController>();

    final body = controller.isLoading
        ? const Padding(padding: EdgeInsets.all(AppSizes.pageHPad), child: ShimmerCardList(itemHeight: 150))
        : controller.requests.isEmpty
            ? const EmptyState(icon: Icons.inbox_outlined, title: 'No pending requests', message: 'New booking requests from clients will appear here.')
            : ListView.separated(
                padding: const EdgeInsets.all(AppSizes.pageHPad),
                itemCount: controller.requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                itemBuilder: (context, i) => _RequestCard(booking: controller.requests[i], controller: controller)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                    .slideY(begin: 0.06, end: 0),
              );

    if (widget.embedded) {
      return Scaffold(appBar: AppBar(title: const Text('Booking Requests'), automaticallyImplyLeading: false), body: SafeArea(child: body));
    }
    return Scaffold(appBar: AppBar(title: const Text('Booking Requests')), body: SafeArea(child: body));
  }
}

class _RequestCard extends StatelessWidget {
  final BookingModel booking;
  final ProviderBookingController controller;
  const _RequestCard({required this.booking, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
        boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundColor: AppColors.primary, child: Text(booking.clientName[0], style: const TextStyle(color: Colors.white))),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.clientName, style: AppTextStyles.titleMedium),
                    Text(booking.serviceTitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              Text(Formatters.peso(booking.amount), style: AppTextStyles.titleMedium.copyWith(color: AppColors.secondary)),
            ],
          ),
          Divider(height: AppSizes.lg, color: lineColor),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.neutral300),
              const SizedBox(width: 6),
              Text(Formatters.dateShort(booking.bookingDate), style: AppTextStyles.bodySmall),
              const SizedBox(width: 14),
              const Icon(Icons.access_time_rounded, size: 14, color: AppColors.neutral300),
              const SizedBox(width: 6),
              Text(booking.schedule, style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: OutlinedAppButton(
                  label: 'Decline',
                  color: AppColors.error,
                  onPressed: () async {
                    final confirmed = await AppDialog.confirm(context, title: 'Decline this request?', message: 'The client will be notified this request was declined.', confirmLabel: 'Decline', danger: true);
                    if (confirmed) {
                      await controller.loadProviderBookings();
                      if (context.mounted) AppSnackbar.success(context, 'Request declined.');
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: PrimaryButton(
                  label: 'Accept',
                  onPressed: () async {
                    await controller.accept(booking.id);
                    if (context.mounted) AppSnackbar.success(context, 'Booking accepted!');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
