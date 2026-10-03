import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../booking/controllers/provider_booking_controller.dart';
import '../../booking/models/booking_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/status_badge.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

/// What the provider has earned from completed jobs.
///
/// Customers pay providers directly — SkillServe neither holds nor pays out
/// money — so there is no balance, payout method or withdrawal here. What the
/// platform does record is each job's price, its fee, and whether the customer
/// has paid, and that is exactly what this screen shows.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookings = context.read<ProviderBookingController>();
      // The dashboard usually loaded them already; opened directly, load now.
      if (bookings.bookings.isEmpty && !bookings.isLoading) {
        bookings.loadProviderBookings();
      }
    });
  }

  Future<void> _reload() =>
      context.read<ProviderBookingController>().loadProviderBookings();

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<ProviderBookingController>();
    final completed = bookings.completed.reversed.toList();
    final now = DateTime.now();
    // Same month *and* year: last October is not this October.
    final thisMonth = completed.where(
        (b) => b.bookingDate.year == now.year && b.bookingDate.month == now.month);

    double sum(Iterable<BookingModel> jobs, double Function(BookingModel) value) =>
        jobs.fold<double>(0, (total, b) => total + value(b));

    final gross = sum(completed, (b) => b.amount);
    final fees = sum(completed, (b) => b.platformFee);
    final net = sum(completed, (b) => b.providerEarnings);
    final netThisMonth = sum(thisMonth, (b) => b.providerEarnings);
    final unpaid = sum(completed.where((b) => b.isUnpaid), (b) => b.amount);
    final failed = bookings.errorMessage != null && bookings.bookings.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: SafeArea(
        child: bookings.isLoading
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pageHPad),
                child: ShimmerCardList(itemHeight: 90),
              )
            : failed
                ? ErrorState(message: bookings.errorMessage!, onRetry: _reload)
                : RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      padding: const EdgeInsets.all(AppSizes.pageHPad),
                      children: [
                        _Summary(
                          net: net,
                          netThisMonth: netThisMonth,
                          jobs: completed.length,
                        ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),
                        const SizedBox(height: AppSizes.lg),
                        _Breakdown(gross: gross, fees: fees, net: net, unpaid: unpaid)
                            .animate()
                            .fadeIn(delay: 120.ms, duration: 300.ms),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          'Customers pay you directly with the method they chose when booking. '
                          'SkillServe does not hold your money or pay it out.',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: AppSizes.xl),
                        Text('Completed jobs', style: AppTextStyles.titleLarge),
                        const SizedBox(height: AppSizes.md),
                        if (completed.isEmpty)
                          const EmptyState(
                            icon: AppIcons.payments_outlined,
                            title: 'No earnings yet',
                            message: 'Jobs you complete will appear here with what you earned.',
                          )
                        else
                          for (var i = 0; i < completed.length; i++)
                            _JobRow(job: completed[i])
                                .animate()
                                .fadeIn(
                                    delay: Duration(milliseconds: 200 + i.clamp(0, 8) * 60),
                                    duration: 350.ms)
                                .slideY(begin: 0.05, end: 0),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final double net;
  final double netThisMonth;
  final int jobs;

  const _Summary({required this.net, required this.netThisMonth, required this.jobs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your earnings', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(Formatters.peso(net), style: AppTextStyles.onDark(AppTextStyles.displayLarge)),
          ),
          const SizedBox(height: AppSizes.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'This month: ${Formatters.peso(netThisMonth)}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                '$jobs completed ${jobs == 1 ? 'job' : 'jobs'}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Where the headline figure comes from: job prices less the platform fee.
class _Breakdown extends StatelessWidget {
  final double gross;
  final double fees;
  final double net;
  final double unpaid;

  const _Breakdown({required this.gross, required this.fees, required this.net, required this.unpaid});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget row(String label, String value, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
              Text(value,
                  style: strong
                      ? AppTextStyles.titleMedium
                      : AppTextStyles.bodyMedium),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5), width: 0.8),
      ),
      child: Column(
        children: [
          row('Job prices', Formatters.peso(gross)),
          row('Platform fee', '− ${Formatters.peso(fees)}'),
          Divider(height: AppSizes.lg, color: isDark ? AppColors.lineDark : AppColors.line),
          row('You earn', Formatters.peso(net), strong: true),
          if (unpaid > 0) ...[
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                AppIcon(AppIcons.hourglass_top_rounded, size: 14, color: context.accentInk),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${Formatters.peso(unpaid)} of completed jobs is not yet marked paid.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  final BookingModel job;
  const _JobRow({required this.job});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.push('/booking-details/${job.id}'),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5), width: 0.8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.serviceTitle, style: AppTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    '${job.clientName.isEmpty ? 'Customer' : job.clientName} • ${Formatters.dateShort(job.bookingDate)}',
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Formatters.peso(job.providerEarnings),
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.success)),
                const SizedBox(height: 4),
                StatusBadge(
                  label: job.paymentLabel,
                  tone: job.isPaid
                      ? StatusTone.success
                      : job.isUnpaid
                          ? StatusTone.warning
                          : StatusTone.neutral,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
