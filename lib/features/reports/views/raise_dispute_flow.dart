import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../booking/controllers/booking_controller.dart';
import '../../booking/controllers/provider_booking_controller.dart';
import '../../booking/models/booking_model.dart';
import '../controllers/report_controller.dart';
import 'raise_dispute_sheet.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback/app_bottom_sheet.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/misc/app_icon.dart';

/// Asks what went wrong with booking [bookingId], raises the dispute (with any
/// photos as evidence) and tells the user how it went. [onBusy] brackets the
/// request so the caller can disable its buttons. Returns whether it was raised.
Future<bool> raiseDisputeFlow(BuildContext context, String bookingId, {ValueChanged<bool>? onBusy}) async {
  final draft = await showRaiseDisputeSheet(context);
  if (draft == null || !context.mounted) return false;

  final reports = context.read<ReportController>();
  onBusy?.call(true);
  final dispute = await reports.raiseDispute(bookingId: bookingId, reason: draft.reason, photoPaths: draft.photoPaths);
  onBusy?.call(false);
  if (!context.mounted) return dispute != null;

  if (dispute == null) {
    AppSnackbar.error(context, reports.errorMessage ?? 'Unable to raise this dispute.');
    return false;
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
  return true;
}

/// A booking this account may dispute: under way or finished, and not
/// disputed before (the API takes one dispute per booking). Null when the
/// user backs out.
Future<BookingModel?> pickDisputableBooking(BuildContext context) {
  return AppBottomSheet.show<BookingModel>(context, child: const _DisputableBookings());
}

class _DisputableBookings extends StatefulWidget {
  const _DisputableBookings();

  @override
  State<_DisputableBookings> createState() => _DisputableBookingsState();
}

class _DisputableBookingsState extends State<_DisputableBookings> {
  bool _loading = true;

  bool get _isProvider => context.read<AuthController>().isProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_isProvider) {
      await context.read<ProviderBookingController>().loadProviderBookings();
    } else {
      await context.read<BookingController>().loadClientBookings();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isProvider = context.read<AuthController>().isProvider;
    final all = isProvider
        ? context.watch<ProviderBookingController>().bookings
        : context.watch<BookingController>().bookings;
    final disputed = context.watch<ReportController>().disputes.map((d) => d.bookingId).toSet();
    final bookings = all
        .where((b) =>
            (b.status == BookingStatus.inProgress || b.status == BookingStatus.completed) && !disputed.contains(b.id))
        .toList()
      ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));

    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Which booking?', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSizes.xs),
          Text(
            'A dispute is about a booking that is under way or finished. Pick the one that went wrong.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSizes.md),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(AppSizes.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (bookings.isEmpty)
            const EmptyState(
              icon: AppIcons.gavel_rounded,
              title: 'Nothing to dispute',
              message: 'Once a booking has started or finished, you can raise a dispute about it here.',
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSizes.xs),
                itemBuilder: (context, i) {
                  final booking = bookings[i];
                  final other = isProvider ? booking.clientName : booking.providerName;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const AppIcon(AppIcons.calendar_month_outlined),
                    title: Text(
                      booking.serviceTitle.isEmpty ? 'Booking ${booking.bookingNumber}' : booking.serviceTitle,
                      style: AppTextStyles.titleMedium,
                    ),
                    subtitle: Text(
                      [Formatters.dateShort(booking.bookingDate), if (other.isNotEmpty) other, booking.status == BookingStatus.inProgress ? 'In progress' : 'Completed']
                          .join(' · '),
                      style: AppTextStyles.bodySmall,
                    ),
                    trailing: const AppIcon(AppIcons.chevron_right_rounded, size: 18),
                    onTap: () => Navigator.of(context).pop<BookingModel>(booking),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
