import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/provider_booking_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/cards/booking_card.dart';
import '../../core/widgets/feedback/app_dialog.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../models/booking_model.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

/// Provider's Bookings tab — every status in one place with contextual
/// actions: accept/decline requests, start confirmed jobs, mark complete.
class BookingRequestsScreen extends StatefulWidget {
  final bool embedded;
  const BookingRequestsScreen({super.key, this.embedded = false});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> with SingleTickerProviderStateMixin {
  static const _tabs = ['Requests', 'Confirmed', 'In Progress', 'Completed', 'Cancelled', 'Disputed'];
  late final TabController _tabController = TabController(length: _tabs.length, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderBookingController>().loadProviderBookings();
    });
  }

  List<BookingModel> _forTab(ProviderBookingController c, int tab) {
    switch (tab) {
      case 0:
        return c.requests;
      case 1:
        return c.bookings.where((b) => b.status == BookingStatus.confirmed).toList();
      case 2:
        return c.bookings.where((b) => b.status == BookingStatus.inProgress).toList();
      case 3:
        return c.bookings.where((b) => b.status == BookingStatus.completed).toList();
      case 4:
        return c.bookings.where((b) => b.status == BookingStatus.cancelled).toList();
      default:
        return c.bookings.where((b) => b.status == BookingStatus.disputed).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderBookingController>();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.pageHPad, AppSizes.lg, AppSizes.pageHPad, 0),
            child: Text('Bookings', style: AppTextStyles.displayMedium)
                .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
          ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [for (final t in _tabs) Tab(text: t)],
        ),
        Expanded(
          child: controller.isLoading
              ? const Padding(padding: EdgeInsets.all(AppSizes.pageHPad), child: ShimmerCardList(itemHeight: 130))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    for (var t = 0; t < _tabs.length; t++)
                      _TabList(
                        bookings: _forTab(controller, t),
                        tabIndex: t,
                        controller: controller,
                      ),
                  ],
                ),
        ),
      ],
    );

    if (widget.embedded) return Scaffold(body: SafeArea(child: content));
    return Scaffold(appBar: AppBar(title: const Text('Bookings')), body: SafeArea(child: content));
  }
}

class _TabList extends StatelessWidget {
  final List<BookingModel> bookings;
  final int tabIndex;
  final ProviderBookingController controller;

  const _TabList({required this.bookings, required this.tabIndex, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: tabIndex == 0
            ? AppIcons.inbox_outlined
            : (tabIndex == 4 ? AppIcons.cancel_outlined : (tabIndex == 5 ? AppIcons.gavel_rounded : AppIcons.event_note_outlined)),
        title: 'Nothing here',
        message: 'Bookings in this category will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.pageHPad),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, i) => _ActionableCard(
        booking: bookings[i],
        tabIndex: tabIndex,
        controller: controller,
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
          .slideY(begin: 0.06, end: 0),
    );
  }
}

class _ActionableCard extends StatelessWidget {
  final BookingModel booking;
  final int tabIndex;
  final ProviderBookingController controller;

  const _ActionableCard({required this.booking, required this.tabIndex, required this.controller});

  @override
  Widget build(BuildContext context) {
    switch (tabIndex) {
      case 0:
        return _RequestCard(booking: booking, controller: controller);
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookingCard(booking: booking, isProviderView: true, onTap: () => context.push('/booking-details/${booking.id}')),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedAppButton(
                    label: 'Message client',
                    icon: AppIcons.chat_bubble_outline_rounded,
                    onPressed: () => context.push('/chat-conversation/${booking.clientId}'),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'Start job',
                    icon: AppIcons.play_arrow_rounded,
                    onPressed: () async {
                      await controller.start(booking.id);
                      if (context.mounted) AppSnackbar.success(context, 'Job started — good luck!');
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      case 2:
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
          ],
        );
      default:
        return BookingCard(booking: booking, isProviderView: true, onTap: () => context.push('/booking-details/${booking.id}'));
    }
  }
}

/// Pending request — accept / decline.
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
              Text(Formatters.peso(booking.amount), style: AppTextStyles.monoMd.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
            ],
          ),
          Divider(height: AppSizes.lg, color: lineColor),
          Row(
            children: [
              const AppIcon(AppIcons.calendar_today_rounded, size: 14, color: AppColors.neutral300),
              const SizedBox(width: 6),
              Text(Formatters.dateShort(booking.bookingDate), style: AppTextStyles.bodySmall),
              const SizedBox(width: 14),
              const AppIcon(AppIcons.access_time_rounded, size: 14, color: AppColors.neutral300),
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
                    final confirmed = await AppDialog.confirm(
                      context,
                      title: 'Decline this request?',
                      message: 'The client will be notified this request was declined.',
                      confirmLabel: 'Decline',
                      danger: true,
                    );
                    if (confirmed && context.mounted) {
                      await controller.decline(booking.id);
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
