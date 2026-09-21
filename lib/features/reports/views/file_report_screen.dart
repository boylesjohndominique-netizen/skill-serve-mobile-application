import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../reports/controllers/report_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../booking/controllers/booking_controller.dart';
import '../../booking/controllers/provider_booking_controller.dart';
import '../../booking/models/booking_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/buttons/outlined_app_button.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/inputs/app_text_field.dart';
import '../../reports/models/report_model.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

/// File a complaint about the other party on a booking.
///
/// A report is always tied to a booking — that is what identifies who is being
/// reported and gives support the context — so when one is not supplied the
/// screen asks which booking it is about.
class FileReportScreen extends StatefulWidget {
  final String? bookingId;
  const FileReportScreen({super.key, this.bookingId});

  @override
  State<FileReportScreen> createState() => _FileReportScreenState();
}

class _FileReportScreenState extends State<FileReportScreen> {
  final _detailsController = TextEditingController();
  ReportReason? _reason;
  String? _bookingId;
  bool _loadingBookings = false;

  bool get _isProvider => context.read<AuthController>().isProvider;

  @override
  void initState() {
    super.initState();
    _bookingId = widget.bookingId;
    if (_bookingId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookings());
    }
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _loadingBookings = true);
    if (_isProvider) {
      await context.read<ProviderBookingController>().loadProviderBookings();
    } else {
      await context.read<BookingController>().loadClientBookings();
    }
    if (mounted) setState(() => _loadingBookings = false);
  }

  /// Bookings that can be reported on — anything that actually went ahead.
  List<BookingModel> _reportableBookings() {
    final all = _isProvider
        ? context.watch<ProviderBookingController>().bookings
        : context.watch<BookingController>().bookings;
    return all
        .where((b) => b.status != BookingStatus.pending && b.status != BookingStatus.confirmed)
        .toList()
      ..sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
  }

  bool get _canSubmit =>
      _bookingId != null && _reason != null && _detailsController.text.trim().length >= 10;

  Future<void> _submit() async {
    final controller = context.read<ReportController>();
    final report = await controller.fileReport(
      bookingId: _bookingId!,
      reason: _reason!,
      details: _detailsController.text.trim(),
    );
    if (!mounted) return;

    if (report == null) {
      AppSnackbar.error(context, controller.errorMessage ?? 'Unable to file this report.');
      return;
    }
    _showConfirmation(context, report);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportController>();
    final bookings = widget.bookingId == null ? _reportableBookings() : const <BookingModel>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Report an Issue')),
      body: SafeArea(
        child: _loadingBookings
            ? const LoadingState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.pageHPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What happened?', style: AppTextStyles.displayMedium)
                        .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
                    const SizedBox(height: 6),
                    Text(
                      'Reports are reviewed by our support team. Please share as much detail as you can.',
                      style: AppTextStyles.bodyLarge,
                    ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                    const SizedBox(height: AppSizes.xl),

                    if (widget.bookingId != null)
                      _LinkedBookingNotice(bookingId: widget.bookingId!)
                    else
                      ..._bookingPicker(bookings),

                    const SizedBox(height: AppSizes.xl),
                    Text('Reason', style: AppTextStyles.titleLarge)
                        .animate().fadeIn(delay: 260.ms, duration: 300.ms),
                    const SizedBox(height: AppSizes.sm),
                    for (var i = 0; i < ReportReason.forPeople.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: _ReasonTile(
                          label: ReportReason.forPeople[i].label,
                          selected: _reason == ReportReason.forPeople[i],
                          onTap: () => setState(() => _reason = ReportReason.forPeople[i]),
                        )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 300 + i * 45), duration: 300.ms)
                            .slideX(begin: 0.05, end: 0),
                      ),
                    const SizedBox(height: AppSizes.xl),

                    Text('Details', style: AppTextStyles.titleLarge)
                        .animate().fadeIn(delay: 600.ms, duration: 300.ms),
                    const SizedBox(height: AppSizes.sm),
                    AppTextField(
                      label: 'Tell us more',
                      hint: 'Describe what happened, when, and any supporting facts…',
                      controller: _detailsController,
                      maxLines: 5,
                      maxLength: 2000,
                      // The API needs at least 10 characters to act on a report.
                      onChanged: (_) => setState(() {}),
                    ).animate().fadeIn(delay: 640.ms, duration: 350.ms).slideY(begin: 0.05, end: 0),
                    const SizedBox(height: AppSizes.xxl),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: PrimaryButton(
            label: 'Submit report',
            icon: AppIcons.flag_rounded,
            isLoading: controller.isSubmitting,
            onPressed: _canSubmit && !controller.isSubmitting ? _submit : null,
          ),
        ),
      ),
    );
  }

  List<Widget> _bookingPicker(List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return [
        const EmptyState(
          icon: AppIcons.calendar_month_outlined,
          title: 'Nothing to report yet',
          message:
              'Reports are about a specific booking. Once a job has started or finished, you can report an issue with it here.',
        ),
      ];
    }

    return [
      Text('Which booking?', style: AppTextStyles.titleLarge)
          .animate().fadeIn(delay: 180.ms, duration: 300.ms),
      const SizedBox(height: 4),
      Text(
        'We use the booking to work out who you are reporting.',
        style: AppTextStyles.bodyMedium,
      ),
      const SizedBox(height: AppSizes.sm),
      for (final booking in bookings)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.sm),
          child: _ReasonTile(
            label: booking.serviceTitle.isEmpty ? 'Booking ${booking.id}' : booking.serviceTitle,
            subtitle:
                '${Formatters.dateShort(booking.bookingDate)} · ${_isProvider ? booking.clientName : booking.providerName}',
            selected: _bookingId == booking.id,
            onTap: () => setState(() => _bookingId = booking.id),
          ),
        ),
    ];
  }

  void _showConfirmation(BuildContext context, ReportModel report) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
              child: const AppIcon(AppIcons.check_rounded, color: AppColors.success, size: 32),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: AppSizes.lg),
            Text('Report submitted', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Our support team will review it and you can follow its status in My Reports.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text('Reference #${report.id}',
                style: AppTextStyles.monoMd.copyWith(color: AppColors.secondary)),
            const SizedBox(height: AppSizes.xl),
            PrimaryButton(
              label: 'View my reports',
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.pushReplacement('/my-reports');
              },
            ),
            const SizedBox(height: AppSizes.sm),
            OutlinedAppButton(
              label: 'Done',
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedBookingNotice extends StatelessWidget {
  final String bookingId;
  const _LinkedBookingNotice({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          const AppIcon(AppIcons.link_rounded, size: 16, color: AppColors.info),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              'Linked to booking $bookingId',
              style: AppTextStyles.label.copyWith(color: AppColors.info, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 300.ms);
  }
}

/// Selectable tile used for both the booking picker and the reason list.
class _ReasonTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.secondary.withValues(alpha: 0.06)
                : (isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: selected ? AppColors.secondary : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              AppIcon(
                selected ? AppIcons.radio_button_checked_rounded : AppIcons.radio_button_off_rounded,
                size: 19,
                color: selected ? AppColors.secondary : AppColors.neutral300,
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.bodyLarge),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
