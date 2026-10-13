import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cards/section_card.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/widgets/misc/rating_summary.dart';
import '../../../core/widgets/misc/stat_card.dart';
import '../../booking/controllers/provider_booking_controller.dart';
import '../controllers/statistics_controller.dart';
import '../models/provider_statistics_model.dart';

/// The provider's performance, live: this month's earnings, headline
/// numbers, a monthly chart (completed bookings or earnings), bookings by
/// status, the rating breakdown and the top services — all from the API, and
/// refreshed as bookings and reviews change.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => StatisticsController(
        // Booking notifications reload this list; a change refetches the numbers.
        bookingChanges: context.read<ProviderBookingController>(),
      )..load(),
      child: const _StatisticsView(),
    );
  }
}

class _StatisticsView extends StatefulWidget {
  const _StatisticsView();

  @override
  State<_StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<_StatisticsView> {
  /// Which series the chart plots.
  bool _showEarnings = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<StatisticsController>();
    final stats = controller.statistics;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: SafeArea(
        child: stats == null
            ? (controller.error != null
                ? ErrorState(message: controller.error!, onRetry: controller.load)
                : const Padding(
                    padding: EdgeInsets.all(AppSizes.pageHPad),
                    child: ShimmerCardList(count: 4, itemHeight: 120),
                  ))
            : RefreshIndicator(
                color: context.accentInk,
                onRefresh: controller.load,
                child: ListView(
                  padding: const EdgeInsets.all(AppSizes.pageHPad),
                  children: [
                    _MonthHero(stats: stats).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0),
                    const SizedBox(height: AppSizes.lg),
                    _Headlines(stats: stats),
                    const SizedBox(height: AppSizes.lg),
                    SectionCard(
                      title: _showEarnings ? 'Earnings' : 'Completed bookings',
                      subtitle: 'Last ${controller.months} months',
                      action: _PeriodPicker(
                        months: controller.months,
                        onChanged: controller.setMonths,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SeriesToggle(
                            showEarnings: _showEarnings,
                            onChanged: (value) => setState(() => _showEarnings = value),
                          ),
                          const SizedBox(height: AppSizes.md),
                          _MonthlyChart(monthly: stats.monthly, showEarnings: _showEarnings),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    SectionCard(
                      title: 'Bookings by status',
                      subtitle: '${stats.totalBookings} in total',
                      child: _StatusBreakdown(stats: stats),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    SectionCard(
                      title: 'Ratings',
                      subtitle: 'Your rating is the average of your services\' ratings',
                      child: RatingSummary(
                        average: stats.averageRating,
                        total: stats.ratingBreakdown.values.fold(0, (sum, n) => sum + n),
                        breakdown: stats.ratingBreakdown,
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    SectionCard(
                      title: 'Top services',
                      subtitle: 'By completed bookings',
                      child: _TopServices(services: stats.topServices),
                    ),
                    const SizedBox(height: AppSizes.md),
                    if (stats.generatedAt != null)
                      Center(
                        child: Text(
                          'Live · updated ${Formatters.time(stats.generatedAt!)}',
                          style: AppTextStyles.caption.copyWith(color: context.textMutedColor),
                        ),
                      ),
                    const SizedBox(height: AppSizes.xl),
                  ],
                ),
              ),
      ),
    );
  }
}

/// This month — the one the provider is in — on the dark hero card.
class _MonthHero extends StatelessWidget {
  final ProviderStatistics stats;
  const _MonthHero({required this.stats});

  @override
  Widget build(BuildContext context) {
    final current = stats.currentMonth;
    final monthName = current == null
        ? DateFormat('MMMM y').format(DateTime.now())
        : DateFormat('MMMM y').format(DateTime.parse('${current.month}-01'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppIcon(AppIcons.calendar_month_rounded, size: 16, color: AppColors.secondaryLight),
              const SizedBox(width: 6),
              Text(monthName, style: AppTextStyles.label.copyWith(color: AppColors.secondaryLight, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Text('Earned this month', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark)),
          Text(Formatters.peso(stats.earningsThisMonth), style: AppTextStyles.onDark(AppTextStyles.displayLarge)),
          const SizedBox(height: AppSizes.xs),
          Text(
            '${stats.completedThisMonth} ${stats.completedThisMonth == 1 ? 'booking' : 'bookings'} completed · '
            '${Formatters.peso(stats.earningsTotal)} earned in total',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMutedDark),
          ),
        ],
      ),
    );
  }
}

class _Headlines extends StatelessWidget {
  final ProviderStatistics stats;
  const _Headlines({required this.stats});

  @override
  Widget build(BuildContext context) {
    final rate = stats.completionRate;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSizes.md,
      crossAxisSpacing: AppSizes.md,
      childAspectRatio: 1.35,
      children: [
        StatCard(
          label: 'Rating',
          value: stats.totalReviews == 0 ? 'New' : stats.averageRating.toStringAsFixed(1),
          icon: AppIcons.star_rounded,
        ),
        StatCard(
          label: 'Completion rate',
          value: rate == null ? '–' : '${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 1)}%',
          icon: AppIcons.task_alt_rounded,
        ),
        StatCard(
          label: 'Completed bookings',
          value: '${stats.completedBookings}',
          icon: AppIcons.event_available_rounded,
          onTap: () => context.push('/completed-jobs'),
        ),
        StatCard(
          label: 'Reviews',
          value: '${stats.totalReviews}',
          icon: AppIcons.reviews_rounded,
        ),
      ],
    );
  }
}

class _PeriodPicker extends StatelessWidget {
  final int months;
  final ValueChanged<int> onChanged;
  const _PeriodPicker({required this.months, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        for (final option in StatisticsController.periods)
          ChoiceChip(
            label: Text('${option}M'),
            selected: months == option,
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            selectedColor: AppColors.secondary,
            labelStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: months == option ? AppColors.primary : null,
            ),
            onSelected: (_) => onChanged(option),
          ),
      ],
    );
  }
}

class _SeriesToggle extends StatelessWidget {
  final bool showEarnings;
  final ValueChanged<bool> onChanged;
  const _SeriesToggle({required this.showEarnings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment(value: false, label: Text('Bookings')),
        ButtonSegment(value: true, label: Text('Earnings')),
      ],
      selected: {showEarnings},
      showSelectedIcon: false,
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(visualDensity: VisualDensity.compact, textStyle: WidgetStatePropertyAll(AppTextStyles.label)),
    );
  }
}

/// One bar per month, oldest first; the current month is the highlighted
/// last bar.
class _MonthlyChart extends StatelessWidget {
  final List<MonthlyStat> monthly;
  final bool showEarnings;
  const _MonthlyChart({required this.monthly, required this.showEarnings});

  static const _barArea = 120.0;

  double _value(MonthlyStat m) => showEarnings ? m.earnings : m.completed.toDouble();

  String _label(double value) {
    if (!showEarnings) return value.toStringAsFixed(0);
    if (value >= 1000) return '₱${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)}k';
    return '₱${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final max = monthly.fold<double>(0, (m, e) => _value(e) > m ? _value(e) : m);
    if (max == 0) {
      return SizedBox(
        height: _barArea,
        child: Center(
          child: Text(
            showEarnings ? 'No earnings in this period yet.' : 'No completed bookings in this period yet.',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final dense = monthly.length > 6;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < monthly.length; i++)
          Expanded(
            child: Semantics(
              label: '${monthly[i].label} ${monthly[i].year}: ${_label(_value(monthly[i]))}',
              excludeSemantics: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    child: Text(
                      _value(monthly[i]) == 0 ? '' : _label(_value(monthly[i])),
                      style: AppTextStyles.caption.copyWith(fontSize: dense ? 9 : null),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: dense ? 14 : 24,
                    height: _value(monthly[i]) == 0 ? 3 : (_barArea * _value(monthly[i]) / max).clamp(6, _barArea),
                    decoration: BoxDecoration(
                      color: i == monthly.length - 1
                          ? AppColors.secondary
                          : context.accentInk.withValues(alpha: 0.35),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ).animate().scaleY(
                        begin: 0,
                        end: 1,
                        delay: Duration(milliseconds: 80 + i * 40),
                        duration: 400.ms,
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.bottomCenter,
                      ),
                  const SizedBox(height: 6),
                  Text(
                    monthly[i].label,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: dense ? 9 : null,
                      fontWeight: i == monthly.length - 1 ? FontWeight.w800 : null,
                      color: i == monthly.length - 1 ? context.textPrimaryColor : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final ProviderStatistics stats;
  const _StatusBreakdown({required this.stats});

  @override
  Widget build(BuildContext context) {
    final s = stats.statusBreakdown;
    final rows = <(String, int, Color, String?)>[
      ('New requests', s['pending'] ?? 0, context.warningColor, '/booking-requests'),
      ('Upcoming & in progress', (s['confirmed'] ?? 0) + (s['active'] ?? 0), context.infoColor, '/active-jobs'),
      ('Completed', s['completed'] ?? 0, context.successColor, '/completed-jobs'),
      ('Cancelled', s['cancelled'] ?? 0, context.textMutedColor, null),
      ('Disputed', s['disputed'] ?? 0, context.errorColor, null),
    ];

    return Column(
      children: [
        for (final (label, count, color, route) in rows)
          InkWell(
            onTap: route == null ? null : () => context.push(route),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
                  Text('$count', style: AppTextStyles.titleMedium),
                  if (route != null) ...[
                    const SizedBox(width: 4),
                    AppIcon(AppIcons.chevron_right_rounded, size: 16, color: context.textMutedColor),
                  ] else
                    const SizedBox(width: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TopServices extends StatelessWidget {
  final List<TopService> services;
  const _TopServices({required this.services});

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Text('Complete bookings to see which services do best.', style: AppTextStyles.bodySmall);
    }
    return Column(
      children: [
        for (var i = 0; i < services.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: context.accentSoftColor, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: AppTextStyles.label.copyWith(color: context.onAccentSoftColor, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(child: Text(services[i].title, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(
                  '${services[i].completed} done',
                  style: AppTextStyles.bodySmall,
                ),
                if (services[i].averageRating > 0) ...[
                  const SizedBox(width: AppSizes.sm),
                  AppIcon(AppIcons.star_rounded, size: 12, color: context.starColor),
                  const SizedBox(width: 2),
                  Text(services[i].averageRating.toStringAsFixed(1), style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
