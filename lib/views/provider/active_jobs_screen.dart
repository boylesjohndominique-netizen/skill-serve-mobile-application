import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/provider_booking_controller.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/cards/booking_card.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/constants/app_icons.dart';

/// Bookings the provider has accepted and is actively working on.
class ActiveJobsScreen extends StatefulWidget {
  const ActiveJobsScreen({super.key});

  @override
  State<ActiveJobsScreen> createState() => _ActiveJobsScreenState();
}

class _ActiveJobsScreenState extends State<ActiveJobsScreen> {
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

    return Scaffold(
      appBar: AppBar(title: const Text('Active Jobs')),
      body: SafeArea(
        child: controller.isLoading
            ? const Padding(padding: EdgeInsets.all(AppSizes.pageHPad), child: ShimmerCardList(itemHeight: 130))
            : controller.active.isEmpty
                ? const EmptyState(icon: AppIcons.work_outline_rounded, title: 'No active jobs', message: 'Accepted bookings you\'re currently working on will show up here.')
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.pageHPad),
                    itemCount: controller.active.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                    itemBuilder: (context, i) {
                      final booking = controller.active[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BookingCard(booking: booking, isProviderView: true, onTap: () => context.push('/booking-details/${booking.id}')),
                          const SizedBox(height: AppSizes.sm),
                          PrimaryButton(
                            label: 'Mark as completed',
                            icon: AppIcons.task_alt_rounded,
                            onPressed: () async {
                              await controller.complete(booking.id);
                              if (context.mounted) AppSnackbar.success(context, 'Job marked as completed.');
                            },
                          ),
                          const SizedBox(height: AppSizes.md),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                          .slideY(begin: 0.06, end: 0);
                    },
                  ),
      ),
    );
  }
}
