import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/provider_booking_controller.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/widgets/cards/booking_card.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/constants/app_icons.dart';

/// Provider's job history — completed bookings only.
class CompletedJobsScreen extends StatefulWidget {
  const CompletedJobsScreen({super.key});

  @override
  State<CompletedJobsScreen> createState() => _CompletedJobsScreenState();
}

class _CompletedJobsScreenState extends State<CompletedJobsScreen> {
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
      appBar: AppBar(title: const Text('Completed Jobs')),
      body: SafeArea(
        child: controller.isLoading
            ? const Padding(padding: EdgeInsets.all(AppSizes.pageHPad), child: ShimmerCardList(itemHeight: 130))
            : controller.completed.isEmpty
                ? const EmptyState(icon: AppIcons.task_alt_rounded, title: 'No completed jobs yet', message: 'Your finished bookings will be listed here.')
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.pageHPad),
                    itemCount: controller.completed.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
                    itemBuilder: (context, i) => BookingCard(
                      booking: controller.completed[i],
                      isProviderView: true,
                      onTap: () => context.push('/booking-details/${controller.completed[i].id}'),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                        .slideY(begin: 0.06, end: 0),
                  ),
      ),
    );
  }
}
