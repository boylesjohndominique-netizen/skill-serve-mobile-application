import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/booking_controller.dart';
import '../controllers/provider_booking_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../reports/controllers/report_controller.dart';
import '../../reports/views/raise_dispute_sheet.dart';
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
import '../../../core/widgets/misc/payment_qr_card.dart';
import '../models/booking_model.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/feedback/app_notice.dart';

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

  ChangeNotifier? _bookings;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bookings = _isProviderView
          ? context.read<ProviderBookingController>()
          : context.read<BookingController>();
      _bookings!.addListener(_followList);
      _loadBooking();
    });
  }

  @override
  void dispose() {
    _bookings?.removeListener(_followList);
    super.dispose();
  }

  /// A notification about a booking reloads the booking lists
  /// (NotificationPoller). When this booking's copy there has moved on — the
  /// provider confirmed the GCash payment, accepted, completed it — this
  /// screen reloads too, instead of showing the old status until refreshed.
  void _followList() {
    final current = _booking;
    if (!mounted || current == null || _loading) return;
    final bookings = _isProviderView
        ? context.read<ProviderBookingController>().bookings
        : context.read<BookingController>().bookings;
    final listed = bookings.where((b) => b.id == current.id).firstOrNull;
    if (listed != null &&
        (listed.status != current.status || listed.paymentStatus != current.paymentStatus)) {
      _loadBooking();
    }
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

  /// Where back leads when this screen opened with nothing beneath it — after
  /// confirming a booking, or from a notification: the user's own home.
  String get _home => _isProviderView ? '/provider' : '/client';

  /// Back always has somewhere to go: the previous screen when there is one,
  /// otherwise home. Without this the app bar showed no back button and the
  /// system back gesture closed the app.
  PreferredSizeWidget _appBar(BuildContext context) {
    final canPop = context.canPop();
    return AppBar(
      title: const Text('Booking Details'),
      automaticallyImplyLeading: canPop,
      leading: canPop
          ? null
          : IconButton(
              tooltip: 'Back to home',
              icon: const AppIcon(AppIcons.arrow_back_rounded),
              onPressed: () => context.go(_home),
            ),
    );
  }

  /// [child] with the system back gesture sent home when nothing is beneath.
  Widget _withBackToHome(BuildContext context, Widget child) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(_home);
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _withBackToHome(context, Scaffold(appBar: _appBar(context), body: const LoadingState()));
    }

    final booking = _booking;
    if (booking == null) {
      return _withBackToHome(context, Scaffold(
        appBar: _appBar(context),
        body: SafeArea(
          child: ErrorState(
            message: _error ?? 'This booking could not be loaded.',
            onRetry: _loadBooking,
          ),
        ),
      ));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProviderView = _isProviderView;

    return _withBackToHome(context, Scaffold(
      appBar: _appBar(context),
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
                        'Our support team is reviewing the case. You can track it in My Disputes or contact support anytime.',
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
                    tone: NoticeTone.info,
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
                // The provider's take, with every step of the sum shown.
                if (isProviderView && booking.earnings != null) ...[
                  const SizedBox(height: AppSizes.lg),
                  _EarningsCard(earnings: booking.earnings!, isDark: isDark)
                      .animate()
                      .fadeIn(delay: 280.ms, duration: 350.ms)
                      .slideY(begin: 0.06, end: 0),
                ],
                // How to pay — the customer's own unpaid GCash booking only.
                // The API decides when to send these details; the app never
                // guesses at a provider's payment number.
                if (booking.paymentInstructions != null) ...[
                  const SizedBox(height: AppSizes.lg),
                  _PaymentInstructionsCard(
                    instructions: booking.paymentInstructions!,
                    isDark: isDark,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 350.ms)
                      .slideY(begin: 0.06, end: 0),
                ],
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
                          style: AppTextStyles.monoLg.copyWith(color: context.accentInk),
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
    ));
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
          label: 'Start service',
          icon: AppIcons.play_arrow_rounded,
          isLoading: _acting,
          onPressed: _acting
              ? null
              : () => _act(() => controller.start(booking.id), 'Service started — good luck!'),
        ));
        actions.add(const SizedBox(height: AppSizes.sm));
        actions.add(OutlinedAppButton(
          label: 'Message client',
          icon: AppIcons.chat_bubble_outline_rounded,
          onPressed: () => context.push('/chat-conversation/${booking.id}'),
        ));
        actions.add(const SizedBox(height: AppSizes.sm));
        actions.add(OutlinedAppButton(
          label: 'Cancel booking',
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
              : () => _act(() => controller.complete(booking.id), 'Service marked as completed.'),
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
      title: 'Cancel this booking?',
      message: 'You already accepted this booking. The client will be notified with your reason.'
          '${_lateFeeNotice(booking)}',
      fieldLabel: 'Reason',
      hint: 'e.g. I am unwell and cannot make it that day',
      confirmLabel: 'Cancel booking',
      danger: true,
      minLength: 5,
    );
    if (reason == null || !mounted) return;
    await _act(() => controller.cancel(booking.id, reason: reason), 'Booking cancelled. The customer has been told.');
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
    if (booking.status == BookingStatus.cancelled) {
      actions.add(PrimaryButton(
        label: 'Back to home',
        icon: AppIcons.home_rounded,
        onPressed: () => context.go('/client'),
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
  /// the person. A job that is under way or finished can be disputed once;
  /// once it is, either party follows the case on My Disputes.
  List<Widget> _escalationActions(BuildContext context, BookingModel booking) {
    final canDispute = booking.status == BookingStatus.inProgress ||
        booking.status == BookingStatus.completed;

    return [
      if (booking.status == BookingStatus.disputed) ...[
        const SizedBox(height: AppSizes.sm),
        OutlinedAppButton(
          label: 'Track dispute',
          icon: AppIcons.gavel_rounded,
          onPressed: () => context.push('/my-disputes'),
        ),
      ],
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
        icon: AppIcon(AppIcons.flag_outlined, size: 16, color: context.textMutedColor),
        label: Text('Report an issue',
            style: AppTextStyles.label.copyWith(color: context.textMutedColor)),
      ),
    ];
  }

  Future<void> _raiseDispute(BookingModel booking) async {
    final draft = await showRaiseDisputeSheet(context);
    if (draft == null || !mounted) return;

    final reports = context.read<ReportController>();
    setState(() => _acting = true);
    final dispute = await reports.raiseDispute(
      bookingId: booking.id,
      reason: draft.reason,
      photoPaths: draft.photoPaths,
    );
    if (!mounted) return;
    setState(() => _acting = false);

    if (dispute == null) {
      AppSnackbar.error(context, reports.errorMessage ?? 'Unable to raise this dispute.');
      return;
    }
    final unsent = reports.unsentDisputePhotos;
    if (unsent > 0) {
      AppSnackbar.error(
        context,
        'Dispute raised, but $unsent ${unsent == 1 ? 'photo' : 'photos'} could not be attached. Add them from My Disputes.',
      );
    } else {
      AppSnackbar.success(context, 'Dispute raised. Our support team will review it.');
    }
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

/// Full-width notice for the dispute, cancellation and reschedule states —
/// the shared [AppNotice], so it reads the same in light and dark mode.
class _Banner extends StatelessWidget {
  final AppIconData icon;
  final String title;
  final String message;
  final NoticeTone tone;

  const _Banner({
    required this.icon,
    required this.title,
    required this.message,
    this.tone = NoticeTone.error,
  });

  @override
  Widget build(BuildContext context) =>
      AppNotice(tone: tone, icon: icon, title: title, message: message);
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

/// Where to send the money on an unpaid GCash booking.
///
/// SkillServe never holds the payment: the customer sends it to the
/// provider's own GCash number and the provider confirms it afterwards. When
/// the provider has not saved their details, the API says so in [note] and
/// there is nothing to copy.
class _PaymentInstructionsCard extends StatelessWidget {
  const _PaymentInstructionsCard({required this.instructions, required this.isDark});

  final PaymentInstructions instructions;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'How to pay',
      isDark: isDark,
      children: [
        const SizedBox(height: AppSizes.sm),
        // The provider's own GCash QR with this booking's exact amount in it:
        // scanning it pays them directly, amount filled in.
        if (instructions.hasQr) ...[
          Center(
            child: PaymentQrCard(
              payload: instructions.qrPayload,
              amount: instructions.amount,
              saveName: 'skillserve-${instructions.reference}',
              caption: (instructions.gcashName ?? '').isEmpty ? null : 'To ${instructions.gcashName}',
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Scan this with GCash or any QR Ph app — the amount is filled in. Paying on this phone? '
            'Save the QR, then in GCash tap Pay QR → Upload QR and choose it.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSizes.md),
        ],
        if ((instructions.gcashNumber ?? '').isNotEmpty) ...[
          InfoRow(
              icon: AppIcons.account_balance_wallet_rounded,
              label: 'GCash number',
              value: instructions.gcashNumber!),
          InfoRow(
              icon: AppIcons.person_outline_rounded,
              label: 'Account name',
              value: (instructions.gcashName ?? '').isEmpty ? '—' : instructions.gcashName!),
          InfoRow(
              icon: AppIcons.payments_outlined,
              label: 'Amount',
              value: '₱${instructions.amount}'),
          InfoRow(
              icon: AppIcons.receipt_long_outlined,
              label: 'Reference',
              value: instructions.reference.isEmpty ? '—' : instructions.reference),
        ],
        const SizedBox(height: AppSizes.sm),
        Text(instructions.note, style: AppTextStyles.bodyMedium),
        if ((instructions.gcashNumber ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSizes.md),
          OutlinedAppButton(
            label: 'Copy GCash number',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: instructions.gcashNumber!));
              if (context.mounted) {
                AppSnackbar.success(context, 'GCash number copied.');
              }
            },
          ),
        ],
      ],
    );
  }
}

/// ─── Vertical status timeline ───
class _Timeline extends StatelessWidget {
  final List<BookingTimelineEntry> entries;
  const _Timeline({required this.entries});

  Color _colorFor(BuildContext context, String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'inProgress':
      case 'in_progress':
        return context.infoColor;
      case 'cancelled':
      case 'disputed':
        return AppColors.error;
      case 'pending':
      case 'confirmed':
        return context.accentInk; // brass
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
                          color: _colorFor(context, entries[i].status),
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
                            color: _colorFor(context, entries[i].status).withValues(alpha: 0.3),
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

/// What the provider receives from this booking: the price, SkillServe's
/// commission and the rest, then where that commission stands.
class _EarningsCard extends StatelessWidget {
  final BookingEarnings earnings;
  final bool isDark;
  const _EarningsCard({required this.earnings, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rate = earnings.commissionRate;
    final rateLabel = rate == null ? '' : ' (${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 2)}%)';

    Widget line(String label, String value, {bool strong = false, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: strong ? AppTextStyles.titleMedium : AppTextStyles.bodyMedium),
              ),
              Text(
                value,
                style: (strong ? AppTextStyles.monoLg : AppTextStyles.monoMd).copyWith(
                  color: color,
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        );

    final (tone, message) = switch (earnings.commissionStatus) {
      'outstanding' => (NoticeTone.warning, 'You owe SkillServe ${Formatters.peso(earnings.commission)} for this booking. Pay it under Commission to keep taking new bookings.'),
      'settled' => (
          NoticeTone.success,
          earnings.commissionSettledAt == null
              ? 'SkillServe\'s share is paid.'
              : 'SkillServe\'s share was paid on ${Formatters.dateShort(earnings.commissionSettledAt!)}.',
        ),
      'waived' => (NoticeTone.success, 'SkillServe waived its share — you keep the full ${Formatters.peso(earnings.price)}.'),
      'voided' => (NoticeTone.info, 'This booking was cancelled, so nothing is earned and no commission is due.'),
      _ => (NoticeTone.info, 'SkillServe\'s share becomes due once you record the customer\'s payment.'),
    };

    return _SectionCard(
      title: 'Your earnings',
      isDark: isDark,
      children: [
        line('Price the customer pays', Formatters.peso(earnings.price)),
        line('SkillServe commission$rateLabel', '− ${Formatters.peso(earnings.commission)}', color: context.errorColor),
        Divider(height: AppSizes.lg, color: isDark ? AppColors.lineDark : AppColors.line),
        line('You receive', Formatters.peso(earnings.providerReceives), strong: true, color: context.accentInk),
        const SizedBox(height: AppSizes.sm),
        AppNotice(
          tone: tone,
          message: message,
          action: earnings.commissionStatus == 'outstanding'
              ? TextButton(onPressed: () => context.push('/commissions'), child: const Text('Open Commission'))
              : null,
        ),
      ],
    );
  }
}
