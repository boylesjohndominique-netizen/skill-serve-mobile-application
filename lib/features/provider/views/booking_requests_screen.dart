import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../booking/controllers/provider_booking_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons/outlined_app_button.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/cards/booking_card.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../booking/models/booking_model.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/app_avatar.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// Provider's Bookings tab — every status in one place with contextual
/// actions: accept/decline requests, start confirmed jobs, mark complete.
class BookingRequestsScreen extends StatefulWidget {
  final bool embedded;
  const BookingRequestsScreen({super.key, this.embedded = false});

  @override
  State<BookingRequestsScreen> createState() => _BookingRequestsScreenState();
}

class _BookingRequestsScreenState extends State<BookingRequestsScreen> with SingleTickerProviderStateMixin {
  static const _tabs = <(String, List<BookingStatus>)>[
    ('Requests', [BookingStatus.pending]),
    ('Confirmed', [BookingStatus.confirmed]),
    ('In Progress', [BookingStatus.inProgress]),
    ('Completed', [BookingStatus.completed]),
    ('Cancelled', [BookingStatus.cancelled]),
    ('Disputed', [BookingStatus.disputed]),
  ];

  late final TabController _tabController = TabController(length: _tabs.length, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderBookingController>().loadProviderBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reload() =>
      context.read<ProviderBookingController>().loadProviderBookings();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProviderBookingController>();
    final failed = controller.errorMessage != null && controller.bookings.isEmpty;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.pageHPad, AppSizes.lg, AppSizes.pageHPad, 0),
            child: Text('Bookings', style: AppTextStyles.displayMedium)
                .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
          ),
        if (failed)
          Expanded(child: ErrorState(message: controller.errorMessage!, onRetry: _reload))
        else ...[
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final t in _tabs) Tab(text: t.$1)],
          ),
          Expanded(
            child: controller.isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppSizes.pageHPad),
                    child: ShimmerCardList(itemHeight: 130),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      for (var t = 0; t < _tabs.length; t++)
                        _TabList(
                          bookings: controller.withStatus(_tabs[t].$2),
                          tabIndex: t,
                          controller: controller,
                          onRefresh: _reload,
                        ),
                    ],
                  ),
          ),
        ],
      ],
    );

    if (widget.embedded) return Scaffold(body: SafeArea(child: content));
    return Scaffold(appBar: AppBar(title: const Text('Bookings')), body: SafeArea(child: content));
  }
}

/// Runs a status change and reports its outcome — the controller keeps the
/// list in step, so the card moves to its new tab on success.
Future<void> _runAction(
  BuildContext context,
  Future<bool> Function() action,
  String successMessage,
) async {
  final controller = context.read<ProviderBookingController>();
  final ok = await action();
  if (!context.mounted) return;
  if (ok) {
    AppSnackbar.success(context, successMessage);
  } else {
    AppSnackbar.error(
        context, controller.errorMessage ?? 'That did not work. Please try again.');
  }
}

class _TabList extends StatelessWidget {
  final List<BookingModel> bookings;
  final int tabIndex;
  final ProviderBookingController controller;
  final Future<void> Function() onRefresh;

  const _TabList({
    required this.bookings,
    required this.tabIndex,
    required this.controller,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: bookings.isEmpty
          ? ListView(
              padding: const EdgeInsets.only(top: AppSizes.xxl),
              children: [
                EmptyState(
                  icon: tabIndex == 0
                      ? AppIcons.inbox_outlined
                      : (tabIndex == 4
                          ? AppIcons.cancel_outlined
                          : (tabIndex == 5 ? AppIcons.gavel_rounded : AppIcons.event_note_outlined)),
                  title: 'Nothing here',
                  message: 'Bookings in this category will appear here.',
                ),
              ],
            )
          : ListView.separated(
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
            ),
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
    final busy = controller.busyBookingId == booking.id;

    switch (tabIndex) {
      case 0:
        return _RequestCard(booking: booking, controller: controller, busy: busy);
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
                    onPressed: () => context.push('/chat-conversation/${booking.id}'),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: PrimaryButton(
                    label: 'Start job',
                    icon: AppIcons.play_arrow_rounded,
                    isLoading: busy,
                    onPressed: busy
                        ? null
                        : () => _runAction(context, () => controller.start(booking.id),
                            'Job started — good luck!'),
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
              isLoading: busy,
              onPressed: busy
                  ? null
                  : () => _runAction(context, () => controller.complete(booking.id),
                      'Job marked as completed.'),
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
  final bool busy;

  const _RequestCard({required this.booking, required this.controller, required this.busy});

  Future<void> _decline(BuildContext context) async {
    final reason = await AppDialog.prompt(
      context,
      title: 'Decline this request?',
      message: 'The client will be notified this request was declined.',
      fieldLabel: 'Reason (optional)',
      hint: 'Let the client know why, e.g. fully booked that day',
      confirmLabel: 'Decline',
      danger: true,
    );
    if (reason == null || !context.mounted) return;
    await _runAction(
        context, () => controller.decline(booking.id, reason: reason), 'Request declined.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;
    final clientName = booking.clientName.isEmpty ? 'Customer' : booking.clientName;

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
              AppAvatar(initials: clientName[0].toUpperCase(), radius: 20),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(clientName, style: AppTextStyles.titleMedium),
                    Text(booking.serviceTitle, style: AppTextStyles.bodySmall),
                    // The customer moved this booking, possibly after it was
                    // accepted, so the time needs a fresh answer.
                    if (booking.isRescheduledRequest) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.infoBg,
                          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        child: Text('Rescheduled',
                            style: AppTextStyles.caption.copyWith(color: context.infoColor)),
                      ),
                    ],
                  ],
                ),
              ),
              Text(Formatters.peso(booking.amount), style: AppTextStyles.monoMd.copyWith(color: context.accentInk, fontWeight: FontWeight.w700)),
            ],
          ),
          Divider(height: AppSizes.lg, color: lineColor),
          Row(
            children: [
              AppIcon(AppIcons.calendar_today_rounded, size: 14, color: context.textMutedColor),
              const SizedBox(width: 6),
              Text(Formatters.dateShort(booking.bookingDate), style: AppTextStyles.bodySmall),
              const SizedBox(width: 14),
              AppIcon(AppIcons.access_time_rounded, size: 14, color: context.textMutedColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(booking.schedule,
                    style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          if (booking.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                AppIcon(AppIcons.location_on_outlined, size: 14, color: context.textMutedColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(booking.address,
                      style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: OutlinedAppButton(
                  label: 'Decline',
                  color: AppColors.error,
                  onPressed: busy ? null : () => _decline(context),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: PrimaryButton(
                  label: 'Accept',
                  isLoading: busy,
                  onPressed: busy
                      ? null
                      : () => _runAction(
                          context, () => controller.accept(booking.id), 'Booking accepted!'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
