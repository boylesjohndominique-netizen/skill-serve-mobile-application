import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/booking_controller.dart';
import '../controllers/provider_booking_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../reports/controllers/report_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons/outlined_app_button.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/misc/status_badge.dart';
import '../../../core/widgets/misc/info_row.dart';
import '../models/booking_model.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  BookingModel? _booking;
  bool _loading = true;
  String? _error;
  bool _acting = false;

  /// Providers read their own job through the provider endpoint, which is the
  /// only one that carries the customer's contact details.
  bool get _isProviderView => context.read<AuthController>().isProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBooking());
  }

  Future<void> _loadBooking() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final booking = _isProviderView
        ? await context.read<ProviderBookingController>().loadBooking(widget.bookingId)
        : await context.read<BookingController>().loadBooking(widget.bookingId);

    if (!mounted) return;
    setState(() {
      _booking = booking;
      _error = booking == null
          ? (_isProviderView
                  ? context.read<ProviderBookingController>().errorMessage
                  : context.read<BookingController>().errorMessage) ??
              'This booking could not be loaded.'
          : null;
      _loading = false;
    });
  }

  /// Runs a status change, shows its outcome and keeps the screen in step
  /// with the booking the API returned.
  Future<void> _act(Future<bool> Function() action, String successMessage) async {
    setState(() => _acting = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _acting = false);

    if (ok) {
      AppSnackbar.success(context, successMessage);
      await _loadBooking();
      return;
    }
    final message = _isProviderView
        ? context.read<ProviderBookingController>().errorMessage
        : context.read<BookingController>().errorMessage;
    if (mounted) AppSnackbar.error(context, message ?? 'That did not work. Please try again.');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingState());

    final booking = _booking;
    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: SafeArea(
          child: ErrorState(
            message: _error ?? 'This booking could not be loaded.',
            onRetry: _loadBooking,
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProviderView = _isProviderView;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadBooking,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.pageHPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        booking.bookingNumber.isEmpty ? '#${booking.id}' : booking.bookingNumber,
                        style: AppTextStyles.monoSm,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    StatusBadge.fromStatus(booking.status.name),
                  ],
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: AppSizes.sm),
                Text(booking.serviceTitle, style: AppTextStyles.displayMedium)
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 350.ms)
                    .slideY(begin: 0.08, end: 0),
                const SizedBox(height: AppSizes.xl),

                // Disputed banner
                if (booking.status == BookingStatus.disputed) ...[
                  const _Banner(
                    icon: AppIcons.gavel_rounded,
                    title: 'This booking is under dispute',
                    message:
                        'Our support team is reviewing the case. You can track progress in Reports or contact support anytime.',
                  )
                      .animate()
                      .fadeIn(delay: 130.ms, duration: 350.ms)
                      .slideY(begin: 0.06, end: 0),
                  const SizedBox(height: AppSizes.lg),
                ],

                // Why it was called off — the API records a reason for both
                // a customer cancellation and a provider decline.
                if (booking.status == BookingStatus.cancelled &&
                    ((booking.cancellationReason?.isNotEmpty ?? false) || (booking.cancellationFee ?? 0) > 0)) ...[
                  _Banner(
                    icon: AppIcons.cancel_outlined,
                    title: 'Booking cancelled',
                    message: ((booking.cancellationReason?.isNotEmpty ?? false)
                            ? 'Reason: ${booking.cancellationReason}'
                            : 'No reason was given.') +
                        ((booking.cancellationFee ?? 0) > 0
                            ? '\nLate-cancellation fee: ${Formatters.peso(booking.cancellationFee!)}'
                            : ''),
                  )
                      .animate()
                      .fadeIn(delay: 130.ms, duration: 350.ms)
                      .slideY(begin: 0.06, end: 0),
                  const SizedBox(height: AppSizes.lg),
                ],

                // A moved request: the provider may have accepted the old
                // time, so say why it is back among their requests.
                if (booking.isRescheduledRequest) ...[
                  _Banner(
                    icon: AppIcons.schedule_rounded,
                    title: isProviderView ? 'Rescheduled by the customer' : 'Waiting for the new time to be accepted',
                    message: isProviderView
                        ? 'The customer moved this booking to ${Formatters.dateShort(booking.bookingDate)}, ${booking.schedule}. Accept or decline the new time.'
                        : 'You moved this booking. It is confirmed once the provider accepts the new time.',
                    color: AppColors.info,
                    background: AppColors.infoBg,
                  )
                      .animate()
                      .fadeIn(delay: 130.ms, duration: 350.ms)
                      .slideY(begin: 0.06, end: 0),
                  const SizedBox(height: AppSizes.lg),
                ],

                _SectionCard(
                  title: 'Schedule',
                  isDark: isDark,
                  children: [
                    InfoRow(
                        icon: AppIcons.calendar_today_rounded,
                        label: 'Date',
                        value: Formatters.dateShort(booking.bookingDate)),
                    InfoRow(
                        icon: AppIcons.access_time_rounded,
                        label: 'Time',
                        value: booking.schedule),
                    if (booking.serviceDuration.isNotEmpty)
                      InfoRow(
                          icon: AppIcons.schedule_rounded,
                          label: 'Duration',
                          value: booking.serviceDuration),
                    InfoRow(
                        icon: AppIcons.location_on_outlined,
                        label: 'Address',
                        value: booking.address.isEmpty ? 'Not provided' : booking.address),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 350.ms)
                    .slideY(begin: 0.06, end: 0),
                const SizedBox(height: AppSizes.lg),
                _SectionCard(
                  title: isProviderView ? 'Customer' : 'Provider',
                  isDark: isDark,
                  children: [
                    if (isProviderView) ...[
                      InfoRow(
                          icon: AppIcons.person_outline_rounded,
                          label: 'Name',
                          value: booking.clientName.isEmpty ? '—' : booking.clientName),
                      InfoRow(
                          icon: AppIcons.phone_outlined,
                          label: 'Contact',
                          value: booking.clientPhone.isEmpty ? 'Not provided' : booking.clientPhone),
                    ] else
                      InfoRow(
                          icon: AppIcons.handyman_outlined,
                          label: 'Provider',
                          value: booking.providerName.isEmpty ? '—' : booking.providerName),
                    InfoRow(
                        icon: AppIcons.account_balance_wallet_rounded,
                        label: 'Payment',
                        value: '${booking.paymentMethod} · ${booking.paymentLabel}'),
                    if (booking.refundedAmount > 0)
                      InfoRow(
                          icon: AppIcons.currency_exchange_rounded,
                          label: 'Refunded',
                          value: Formatters.peso(booking.refundedAmount)),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 250.ms, duration: 350.ms)
                    .slideY(begin: 0.06, end: 0),
                if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.lg),
                  _SectionCard(title: 'Notes', isDark: isDark, children: [
                    Text(booking.notes!, style: AppTextStyles.bodyLarge)
                  ])
                      .animate()
                      .fadeIn(delay: 350.ms, duration: 350.ms)
                      .slideY(begin: 0.06, end: 0),
                ],
                const SizedBox(height: AppSizes.lg),
                Container(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text('Total amount', style: AppTextStyles.titleMedium)),
                      const SizedBox(width: AppSizes.sm),
                      Flexible(
                        child: Text(
                          Formatters.peso(booking.amount),
                          style: AppTextStyles.monoLg.copyWith(color: AppColors.secondary),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 350.ms)
                    .slideY(begin: 0.06, end: 0),

                // ── Timeline ──
                if (booking.timeline.isNotEmpty) ...[
                  const SizedBox(height: AppSizes.xl),
                  Text('Timeline', style: AppTextStyles.titleLarge)
                      .animate()
                      .fadeIn(delay: 440.ms, duration: 300.ms),
                  const SizedBox(height: AppSizes.md),
                  _Timeline(entries: booking.timeline)
                      .animate()
                      .fadeIn(delay: 480.ms, duration: 350.ms)
                      .slideY(begin: 0.05, end: 0),
                ],

                const SizedBox(height: AppSizes.xxl),
                _buildActions(context, booking, isProviderView),
                const SizedBox(height: AppSizes.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, BookingModel booking, bool isProviderView) {
    return isProviderView
        ? _providerActions(context, booking)
        : _clientActions(context, booking);
  }

  /// Accept / decline a request, start a confirmed job, complete one in
  /// progress — the same transitions the API allows, and nothing else.
  Widget _providerActions(BuildContext context, BookingModel booking) {
    final controller = context.read<ProviderBookingController>();
    final actions = <Widget>[];

    switch (booking.status) {
      case BookingStatus.pending:
        actions.add(PrimaryButton(
          label: 'Accept request',
          icon: AppIcons.check_rounded,
          isLoading: _acting,
          onPressed: _acting
              ? null
              : () => _act(() => controller.accept(booking.id), 'Booking accepted!'),
        ));
        actions.add(const SizedBox(height: AppSizes.sm));
        actions.add(OutlinedAppButton(
          label: 'Decline request',
          icon: AppIcons.close_rounded,
          color: AppColors.error,
          onPressed: _acting ? null : () => _declineRequest(booking, controller),
        ));
      case BookingStatus.confirmed:
        actions.add(PrimaryButton(
          label: 'Start job',
          icon: AppIcons.play_arrow_rounded,
          isLoading: _acting,
          onPressed: _acting
              ? null
              : () => _act(() => controller.start(booking.id), 'Job started — good luck!'),
        ));
        actions.add(const SizedBox(height: AppSizes.sm));
        actions.add(OutlinedAppButton(
          label: 'Message client',
          icon: AppIcons.chat_bubble_outline_rounded,
          onPressed: () => context.push('/chat-conversation/${booking.id}'),
        ));
        actions.add(const SizedBox(height: AppSizes.sm));
        actions.add(OutlinedAppButton(
          label: 'Cancel job',
          icon: AppIcons.close_rounded,
          color: AppColors.error,
          onPressed: _acting ? null : () => _cancelAcceptedJob(booking, controller),
        ));
      case BookingStatus.inProgress:
        actions.add(PrimaryButton(
          label: 'Mark as completed',
          icon: AppIcons.task_alt_rounded,
          isLoading: _acting,
          onPressed: _acting
              ? null
              : () => _act(() => controller.complete(booking.id), 'Job marked as completed.'),
        ));
      case BookingStatus.completed when booking.canRecordPayment:
        actions.add(PrimaryButton(
          label: 'Payment received',
          icon: AppIcons.payments_outlined,
          isLoading: _acting,
          onPressed: _acting ? null : () => _recordPayment(booking, controller),
        ));
      default:
        break;
    }
    actions.addAll(_escalationActions(context, booking));
    return Column(children: actions);
  }

  Future<void> _declineRequest(
    BookingModel booking,
    ProviderBookingController controller,
  ) async {
    final reason = await AppDialog.prompt(
      context,
      title: 'Decline this request?',
      message: 'The client will be notified that this request was declined.',
      fieldLabel: 'Reason (optional)',
      hint: 'Let the client know why, e.g. fully booked that day',
      confirmLabel: 'Decline',
      danger: true,
    );
    if (reason == null || !mounted) return;
    await _act(() => controller.decline(booking.id, reason: reason), 'Request declined.');
  }

  /// Payment happens off-platform (cash, GCash, …), so the provider records
  /// it once they have it; a reference number is optional.
  Future<void> _recordPayment(
    BookingModel booking,
    ProviderBookingController controller,
  ) async {
    final reference = await AppDialog.prompt(
      context,
      title: 'Payment received?',
      message:
          'Confirm the customer paid ${Formatters.peso(booking.amount)} by ${booking.paymentMethod}. They will be notified, and this cannot be undone from the app.',
      fieldLabel: 'Reference number (optional)',
      hint: 'e.g. a GCash or bank transfer reference',
      confirmLabel: 'Confirm payment',
      maxLength: 100,
    );
    if (reference == null || !mounted) return;
    await _act(
      () => controller.recordPayment(booking.id, reference: reference),
      'Payment recorded.',
    );
  }

  /// An accepted job can still be called off before it starts, but the
  /// customer was counting on it, so the API requires a reason.
  Future<void> _cancelAcceptedJob(
    BookingModel booking,
    ProviderBookingController controller,
  ) async {
    final reason = await AppDialog.prompt(
      context,
      title: 'Cancel this job?',
      message: 'You already accepted this booking. The client will be notified with your reason.'
          '${_lateFeeNotice(booking)}',
      fieldLabel: 'Reason',
      hint: 'e.g. I am unwell and cannot make it that day',
      confirmLabel: 'Cancel job',
      danger: true,
      minLength: 5,
    );
    if (reason == null || !mounted) return;
    await _act(() => controller.cancel(booking.id, reason: reason), 'Job cancelled. The client has been told.');
  }

  Widget _clientActions(BuildContext context, BookingModel booking) {
    final controller = context.read<BookingController>();
    final actions = <Widget>[];

    if (booking.isReschedulable) {
      actions.add(OutlinedAppButton(
        label: 'Reschedule',
        icon: AppIcons.calendar_today_rounded,
        onPressed: _acting ? null : () => _reschedule(booking),
      ));
      actions.add(const SizedBox(height: AppSizes.sm));
    }
    if (booking.isCancellable) {
      actions.add(OutlinedAppButton(
        label: 'Cancel booking',
        icon: AppIcons.close_rounded,
        color: AppColors.error,
        onPressed: _acting ? null : () => _cancelBooking(booking, controller),
      ));
    }
    if (booking.canBeReviewed) {
      actions.add(PrimaryButton(
        label: 'Leave a review',
        icon: AppIcons.star_border_rounded,
        onPressed: () => context.push('/write-review/${booking.id}'),
      ));
    }
    if (booking.status == BookingStatus.disputed) {
      actions.add(OutlinedAppButton(
        label: 'Contact support',
        icon: AppIcons.support_agent_rounded,
        onPressed: () => context.push('/help-center'),
      ));
    }
    actions.addAll(_escalationActions(context, booking));
    return Column(children: actions);
  }

  /// Escalation paths open to either party: dispute the job itself, or report
  /// the person. A job that is under way or finished can be disputed once.
  List<Widget> _escalationActions(BuildContext context, BookingModel booking) {
    final canDispute = booking.status == BookingStatus.inProgress ||
        booking.status == BookingStatus.completed;

    return [
      if (canDispute) ...[
        const SizedBox(height: AppSizes.sm),
        OutlinedAppButton(
          label: 'Raise a dispute',
          icon: AppIcons.gavel_rounded,
          color: AppColors.error,
          onPressed: _acting ? null : () => _raiseDispute(booking),
        ),
      ],
      const SizedBox(height: AppSizes.sm),
      TextButton.icon(
        onPressed: () => context.push('/file-report?bookingId=${booking.id}'),
        icon: const AppIcon(AppIcons.flag_outlined, size: 16, color: AppColors.neutral300),
        label: Text('Report an issue',
            style: AppTextStyles.label.copyWith(color: AppColors.neutral300)),
      ),
    ];
  }

  Future<void> _raiseDispute(BookingModel booking) async {
    final reason = await AppDialog.prompt(
      context,
      title: 'Raise a dispute?',
      message:
          'Our support team will review this booking and contact both of you. Tell us what went wrong.',
      fieldLabel: 'What went wrong?',
      hint: 'Describe the problem in at least 10 characters',
      confirmLabel: 'Raise dispute',
      danger: true,
      maxLength: 2000,
    );
    if (reason == null || !mounted) return;

    final reports = context.read<ReportController>();
    setState(() => _acting = true);
    final dispute = await reports.raiseDispute(bookingId: booking.id, reason: reason);
    if (!mounted) return;
    setState(() => _acting = false);

    if (dispute == null) {
      AppSnackbar.error(context, reports.errorMessage ?? 'Unable to raise this dispute.');
      return;
    }
    AppSnackbar.success(context, 'Dispute raised. Our support team will review it.');
    await _loadBooking();
  }

  Future<void> _reschedule(BookingModel booking) async {
    final moved = await context.push<bool>('/reschedule-booking/${booking.id}');
    if (moved == true && mounted) await _loadBooking();
  }

  /// The platform's late-cancellation rule, when cancelling now would cost
  /// something (System Settings → Booking).
  String _lateFeeNotice(BookingModel booking) {
    final policy = booking.cancellationPolicy;
    if (policy == null || !policy.chargesFee) return '';
    return '\n\nThis is within ${policy.windowHours} hours of the start, so a late-cancellation fee of '
        '${Formatters.peso(policy.feeIfCancelledNow)} (${policy.feePercent.toStringAsFixed(0)}%) will be recorded.';
  }

  Future<void> _cancelBooking(BookingModel booking, BookingController controller) async {
    final providerName =
        booking.providerName.isEmpty ? 'the provider' : booking.providerName;
    final reason = await AppDialog.prompt(
      context,
      title: 'Cancel this booking?',
      message: 'This will notify $providerName that the booking is cancelled.${_lateFeeNotice(booking)}',
      fieldLabel: 'Reason (optional)',
      hint: 'Why are you cancelling?',
      confirmLabel: 'Cancel booking',
      danger: true,
    );
    if (reason == null || !mounted) return;

    setState(() => _acting = true);
    final cancelled = await controller.cancel(booking.id, reason: reason);
    if (!mounted) return;
    setState(() {
      _acting = false;
      if (cancelled != null) _booking = cancelled;
    });

    if (cancelled != null) {
      AppSnackbar.success(context, 'Booking cancelled.');
    } else {
      AppSnackbar.error(
          context, controller.errorMessage ?? 'Unable to cancel this booking.');
    }
  }
}

/// Full-width tinted notice used for the dispute, cancellation and
/// reschedule banners.
class _Banner extends StatelessWidget {
  final AppIconData icon;
  final String title;
  final String message;
  final Color color;
  final Color background;

  const _Banner({
    required this.icon,
    required this.title,
    required this.message,
    this.color = AppColors.error,
    this.background = AppColors.errorBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          AppIcon(icon, color: color, size: 22),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.titleMedium.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(message,
                    style: AppTextStyles.bodySmall.copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;
  const _SectionCard(
      {required this.title, required this.children, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
        boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
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

/// ─── Vertical status timeline ───
class _Timeline extends StatelessWidget {
  final List<BookingTimelineEntry> entries;
  const _Timeline({required this.entries});

  Color _colorFor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'inProgress':
      case 'in_progress':
        return AppColors.info;
      case 'cancelled':
      case 'disputed':
        return AppColors.error;
      case 'pending':
      case 'confirmed':
        return AppColors.secondary; // brass
      default:
        return AppColors.neutral400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 20,
                  child: Column(
                    children: [
                      Container(
                        width: 11,
                        height: 11,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: _colorFor(entries[i].status),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              width: 2),
                        ),
                      ),
                      if (i < entries.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: _colorFor(entries[i].status).withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entries[i].label,
                            style: AppTextStyles.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Flexible(
                          child: Text(
                            Formatters.relative(entries[i].at),
                            style: AppTextStyles.bodySmall,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
