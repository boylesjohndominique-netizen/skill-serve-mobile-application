import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../marketplace/models/provider_model.dart';
import '../../marketplace/services/service_service.dart';
import '../controllers/booking_controller.dart';
import '../models/booking_model.dart';
import 'schedule_picker.dart';

/// Lets a customer move a pending or confirmed booking to a new time.
///
/// Offers only slots inside the provider's published hours that fit the
/// booking's current length — the API keeps that length and re-checks the
/// hours and overlaps. Pops `true` once the booking has moved.
class RescheduleBookingScreen extends StatefulWidget {
  final String bookingId;
  const RescheduleBookingScreen({super.key, required this.bookingId});

  @override
  State<RescheduleBookingScreen> createState() => _RescheduleBookingScreenState();
}

class _RescheduleBookingScreenState extends State<RescheduleBookingScreen> {
  BookingModel? _booking;
  ProviderModel? _provider;
  bool _loading = true;
  String? _error;

  late DateTime _date;
  int? _slot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final controller = context.read<BookingController>();
    final booking = await controller.loadBooking(widget.bookingId);
    if (!mounted) return;
    if (booking == null) {
      setState(() {
        _error = controller.errorMessage ?? 'This booking could not be loaded.';
        _loading = false;
      });
      return;
    }

    ProviderModel? provider;
    try {
      provider = await ServiceService().getProviderById(booking.providerId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e, "The provider's hours could not be loaded.");
        _loading = false;
      });
      return;
    }
    if (!mounted) return;

    final tomorrow = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
    final current = DateUtils.dateOnly(booking.bookingDate);
    setState(() {
      _booking = booking;
      _provider = provider;
      _date = current.isBefore(tomorrow) ? tomorrow : current;
      _loading = false;
    });
    _selectFirstSlot();
  }

  int get _durationMinutes => _booking?.length?.inMinutes ?? 60;

  List<int> get _slots =>
      BookingSlots.options(_provider?.availability ?? const [], _date, _durationMinutes);

  DateTime? get _newStart => _slot == null ? null : BookingSlots.at(_date, _slot!);

  bool get _isUnchanged => _newStart != null && _newStart == _booking?.bookingDate;

  void _selectFirstSlot() {
    final slots = _slots;
    setState(() => _slot = slots.isEmpty ? null : slots.first);
  }

  Future<void> _pickDate() async {
    final firstDate = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(firstDate) ? firstDate : _date,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 90)),
      helpText: 'Pick a new date',
    );
    if (picked == null) return;
    setState(() => _date = picked);
    _selectFirstSlot();
  }

  Future<void> _submit() async {
    final booking = _booking!;
    final start = _newStart;
    if (start == null) return;

    if (!start.isAfter(DateTime.now())) {
      AppSnackbar.error(context, 'That time has already passed. Pick a later slot.');
      return;
    }

    final confirmed = await AppDialog.confirm(
      context,
      title: 'Move this booking?',
      message: booking.status == BookingStatus.confirmed
          ? '${_providerName(booking)} accepted the current time, so they will need to accept '
              '${Formatters.dateShort(start)} at ${BookingSlots.label(_slot!)} before it is confirmed again.'
          : '${_providerName(booking)} will see the new time on your request: '
              '${Formatters.dateShort(start)} at ${BookingSlots.label(_slot!)}.',
      confirmLabel: 'Reschedule',
    );
    if (!confirmed || !mounted) return;

    final controller = context.read<BookingController>();
    final moved = await controller.reschedule(booking.id, start);
    if (!mounted) return;

    if (moved == null) {
      AppSnackbar.error(context, controller.errorMessage ?? 'Unable to reschedule this booking.');
      return;
    }
    AppSnackbar.success(context, 'Booking moved. Waiting for the provider to accept.');
    context.pop(true);
  }

  static String _providerName(BookingModel booking) =>
      booking.providerName.isEmpty ? 'Your provider' : booking.providerName;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: LoadingState());

    final booking = _booking;
    final provider = _provider;
    if (booking == null || provider == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reschedule')),
        body: SafeArea(child: ErrorState(message: _error!, onRetry: _load)),
      );
    }

    if (!booking.isReschedulable) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reschedule')),
        body: const SafeArea(
          child: ErrorState(
            message: 'This booking can no longer be rescheduled because the job has started or ended.',
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSaving = context.watch<BookingController>().isSaving;

    return Scaffold(
      appBar: AppBar(title: const Text('Reschedule')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Text(booking.serviceTitle, style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizes.sm),
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(
                children: [
                  const AppIcon(AppIcons.schedule_rounded, size: 18, color: AppColors.neutral400),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      'Currently ${Formatters.dateShort(booking.bookingDate)}, ${booking.schedule}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            if (booking.status == BookingStatus.confirmed) ...[
              const SizedBox(height: AppSizes.sm),
              Text(
                'This booking is confirmed. Moving it sends it back to ${_providerName(booking)} to accept the new time.',
                style: AppTextStyles.bodySmall,
              ),
            ],
            const SizedBox(height: AppSizes.xl),
            SchedulePicker(
              availability: provider.availability,
              providerName: provider.user.firstName,
              date: _date,
              selectedSlot: _slot,
              durationMinutes: _durationMinutes,
              onPickDate: _pickDate,
              onSlotSelected: (slot) => setState(() => _slot = slot),
            ),
            const SizedBox(height: AppSizes.xxl),
            if (_isUnchanged)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: Text('That is the current time. Pick a different slot.',
                    style: AppTextStyles.bodySmall),
              ),
            PrimaryButton(
              label: 'Reschedule booking',
              icon: AppIcons.calendar_today_rounded,
              isLoading: isSaving,
              onPressed: _slot == null || _isUnchanged || isSaving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
