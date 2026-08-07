import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/booking_controller.dart';
import '../../controllers/provider_booking_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/buttons/outlined_app_button.dart';
import '../../core/widgets/buttons/primary_button.dart';
import '../../core/widgets/feedback/app_dialog.dart';
import '../../core/widgets/feedback/app_snackbar.dart';
import '../../core/widgets/feedback/loading_state.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../data/mock/mock_data.dart';
import '../../models/booking_model.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

class BookingDetailsScreen extends StatelessWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final all = [...MockData.bookingsForClient, ...MockData.bookingsForProvider];
    final booking = all.where((b) => b.id == bookingId).isNotEmpty
        ? all.firstWhere((b) => b.id == bookingId)
        : null;

    if (booking == null) return const Scaffold(body: LoadingState());

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProviderView = booking.providerId == MockData.currentProvider.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${booking.id}', style: AppTextStyles.monoSm),
                  StatusBadge.fromStatus(booking.status.name),
                ],
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: AppSizes.sm),
              Text(booking.serviceTitle, style: AppTextStyles.displayMedium)
                  .animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: AppSizes.xl),

              // Disputed banner
              if (booking.status == BookingStatus.disputed) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      const AppIcon(AppIcons.gavel_rounded, color: AppColors.error, size: 22),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('This booking is under dispute', style: AppTextStyles.titleMedium.copyWith(color: AppColors.error)),
                            const SizedBox(height: 2),
                            Text(
                              'Our support team is reviewing the case. You can track progress in Reports or contact support anytime.',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 130.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
                const SizedBox(height: AppSizes.lg),
              ],

              _SectionCard(
                title: 'Schedule',
                isDark: isDark,
                children: [
                  _detailRow(AppIcons.calendar_today_rounded, 'Date', Formatters.dateShort(booking.bookingDate)),
                  _detailRow(AppIcons.access_time_rounded, 'Time', booking.schedule),
                  _detailRow(AppIcons.location_on_outlined, 'Address', booking.address.isEmpty ? '—' : booking.address),
                ],
              ).animate().fadeIn(delay: 150.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
              const SizedBox(height: AppSizes.lg),
              _SectionCard(
                title: 'Parties',
                isDark: isDark,
                children: [
                  _detailRow(AppIcons.person_outline_rounded, 'Client', booking.clientName),
                  _detailRow(AppIcons.handyman_outlined, 'Provider', booking.providerName),
                  _detailRow(AppIcons.account_balance_wallet_rounded, 'Payment', booking.paymentMethod),
                ],
              ).animate().fadeIn(delay: 250.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSizes.lg),
                _SectionCard(title: 'Notes', isDark: isDark, children: [Text(booking.notes!, style: AppTextStyles.bodyLarge)])
                    .animate().fadeIn(delay: 350.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),
              ],
              const SizedBox(height: AppSizes.lg),
              Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total amount', style: AppTextStyles.titleMedium),
                    Text(Formatters.peso(booking.amount), style: AppTextStyles.monoLg.copyWith(color: AppColors.secondary)),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 350.ms).slideY(begin: 0.06, end: 0),

              // ── Timeline ──
              if (booking.timeline.isNotEmpty) ...[
                const SizedBox(height: AppSizes.xl),
                Text('Timeline', style: AppTextStyles.titleLarge)
                    .animate().fadeIn(delay: 440.ms, duration: 300.ms),
                const SizedBox(height: AppSizes.md),
                _Timeline(entries: booking.timeline)
                    .animate().fadeIn(delay: 480.ms, duration: 350.ms).slideY(begin: 0.05, end: 0),
              ],

              const SizedBox(height: AppSizes.xxl),
              _buildActions(context, booking, isProviderView),
              const SizedBox(height: AppSizes.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, BookingModel booking, bool isProviderView) {
    final actions = <Widget>[];

    if (isProviderView) {
      // ── Provider-side contextual actions ──
      switch (booking.status) {
        case BookingStatus.pending:
          actions.add(PrimaryButton(
            label: 'Accept request',
            icon: AppIcons.check_rounded,
            onPressed: () async {
              await context.read<ProviderBookingController>().accept(booking.id);
              if (context.mounted) AppSnackbar.success(context, 'Booking accepted!');
            },
          ));
          actions.add(const SizedBox(height: AppSizes.sm));
          actions.add(OutlinedAppButton(
            label: 'Decline request',
            icon: AppIcons.close_rounded,
            color: AppColors.error,
            onPressed: () async {
              final confirmed = await AppDialog.confirm(
                context,
                title: 'Decline this request?',
                message: 'The client will be notified that this request was declined.',
                confirmLabel: 'Decline',
                danger: true,
              );
              if (confirmed && context.mounted) {
                await context.read<ProviderBookingController>().decline(booking.id);
                if (context.mounted) AppSnackbar.success(context, 'Request declined.');
              }
            },
          ));
        case BookingStatus.confirmed:
          actions.add(PrimaryButton(
            label: 'Start job',
            icon: AppIcons.play_arrow_rounded,
            onPressed: () async {
              await context.read<ProviderBookingController>().start(booking.id);
              if (context.mounted) AppSnackbar.success(context, 'Job started — good luck!');
            },
          ));
          actions.add(const SizedBox(height: AppSizes.sm));
          actions.add(OutlinedAppButton(
            label: 'Message client',
            icon: AppIcons.chat_bubble_outline_rounded,
            onPressed: () => context.push('/chat-conversation/${booking.clientId}'),
          ));
        case BookingStatus.inProgress:
          actions.add(PrimaryButton(
            label: 'Mark as completed',
            icon: AppIcons.task_alt_rounded,
            onPressed: () async {
              await context.read<ProviderBookingController>().complete(booking.id);
              if (context.mounted) AppSnackbar.success(context, 'Job marked as completed.');
            },
          ));
        default:
          break;
      }
      return Column(children: actions);
    }

    // ── Client-side contextual actions ──
    if (booking.status == BookingStatus.pending || booking.status == BookingStatus.confirmed) {
      actions.add(OutlinedAppButton(
        label: 'Cancel booking',
        icon: AppIcons.close_rounded,
        color: AppColors.error,
        onPressed: () async {
          final confirmed = await AppDialog.confirm(
            context,
            title: 'Cancel this booking?',
            message: 'This will notify ${booking.providerName} that the booking is cancelled.',
            confirmLabel: 'Cancel booking',
            danger: true,
          );
          if (confirmed && context.mounted) {
            await context.read<BookingController>().cancel(booking.id);
            if (context.mounted) {
              AppSnackbar.success(context, 'Booking cancelled.');
              context.pop();
            }
          }
        },
      ));
    }
    if (booking.status == BookingStatus.completed) {
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
    actions.add(const SizedBox(height: AppSizes.sm));
    actions.add(TextButton.icon(
      onPressed: () => context.push('/file-report?bookingId=${booking.id}'),
      icon: const AppIcon(AppIcons.flag_outlined, size: 16, color: AppColors.neutral300),
      label: Text('Report an issue', style: AppTextStyles.label.copyWith(color: AppColors.neutral300)),
    ));
    return Column(children: actions);
  }

  Widget _detailRow(AppIconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AppIcon(icon, size: 16, color: AppColors.neutral300),
          const SizedBox(width: AppSizes.sm),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Flexible(
            child: Text(value, style: AppTextStyles.titleMedium, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis),
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
  const _SectionCard({required this.title, required this.children, this.isDark = false});

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
      default:
        return AppColors.warning;
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
                          border: Border.all(color: isDark ? AppColors.surfaceDark : Colors.white, width: 2),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entries[i].label, style: AppTextStyles.titleMedium),
                        Text(Formatters.relative(entries[i].at), style: AppTextStyles.bodySmall),
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
