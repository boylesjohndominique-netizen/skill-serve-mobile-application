import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../controllers/provider_booking_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/cards/booking_card.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/constants/app_icons.dart';

/// Lightweight month calendar showing booking density per day,
/// with the selected day's bookings listed below.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selected = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProviderBookingController>().loadProviderBookings();
    });
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<ProviderBookingController>().bookings;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday % 7;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final selectedDayBookings = bookings.where((b) => _sameDay(b.bookingDate, _selected)).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textOnDark : AppColors.textPrimary;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            // Month navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                  icon: const AppIcon(AppIcons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    '${_monthName(_month.month)} ${_month.year}',
                    style: AppTextStyles.titleLarge,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                  icon: const AppIcon(AppIcons.chevron_right_rounded),
                ),
              ],
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: AppSizes.sm),

            // Day-of-week headers
            Row(
              children: [
                for (final d in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                  Expanded(child: Center(child: Text(d, style: AppTextStyles.caption))),
              ],
            ),
            const SizedBox(height: AppSizes.sm),

            // Calendar grid
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.5), width: 0.8),
                boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                itemCount: firstWeekday + daysInMonth,
                itemBuilder: (context, i) {
                  if (i < firstWeekday) return const SizedBox.shrink();
                  final day = i - firstWeekday + 1;
                  final date = DateTime(_month.year, _month.month, day);
                  final hasBooking = bookings.any((b) => _sameDay(b.bookingDate, date));
                  final selected = _sameDay(date, _selected);
                  final today = _sameDay(date, DateTime.now());

                  return InkWell(
                    onTap: () => setState(() => _selected = date),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.secondary : Colors.transparent,
                          shape: BoxShape.circle,
                          border: today && !selected ? Border.all(color: AppColors.secondary, width: 1.5) : null,
                          boxShadow: selected
                              ? [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$day', style: AppTextStyles.bodyMedium.copyWith(color: selected ? AppColors.primary : textColor)),
                            if (hasBooking)
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.secondary, shape: BoxShape.circle),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.04, end: 0),

            const SizedBox(height: AppSizes.xl),
            Text('Bookings on this day', style: AppTextStyles.titleLarge)
                .animate().fadeIn(delay: 250.ms, duration: 300.ms),
            const SizedBox(height: AppSizes.md),
            if (selectedDayBookings.isEmpty)
              const EmptyState(icon: AppIcons.event_busy_rounded, title: 'No bookings', message: 'You have no bookings scheduled for this day.')
            else
              Column(
                children: [
                  for (var i = 0; i < selectedDayBookings.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.md),
                      child: BookingCard(booking: selectedDayBookings[i], isProviderView: true),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 300 + i * 60), duration: 350.ms)
                        .slideY(begin: 0.06, end: 0),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][m - 1];
}
