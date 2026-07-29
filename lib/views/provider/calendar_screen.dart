import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/provider_booking_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/cards/booking_card.dart';
import '../../core/widgets/feedback/empty_state.dart';

/// Lightweight month calendar (no external calendar package) showing
/// booking density per day, with the selected day's bookings listed below.
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

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(
                  '${_monthName(_month.month)} ${_month.year}',
                  style: AppTextStyles.titleLarge,
                ),
                IconButton(
                  onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [for (final d in const ['S', 'M', 'T', 'W', 'T', 'F', 'S']) Expanded(child: Center(child: Text(d, style: AppTextStyles.caption)))],
            ),
            const SizedBox(height: AppSizes.sm),
            GridView.builder(
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
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected ? AppColors.secondary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: today && !selected ? Border.all(color: AppColors.secondary) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$day', style: AppTextStyles.bodyMedium.copyWith(color: selected ? Colors.white : AppColors.textPrimary)),
                          if (hasBooking)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(color: selected ? Colors.white : AppColors.secondary, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSizes.xl),
            Text('Bookings on this day', style: AppTextStyles.titleLarge),
            const SizedBox(height: AppSizes.md),
            if (selectedDayBookings.isEmpty)
              const EmptyState(icon: Icons.event_busy_rounded, title: 'No bookings', message: 'You have no bookings scheduled for this day.')
            else
              Column(
                children: [
                  for (final b in selectedDayBookings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.md),
                      child: BookingCard(booking: b, isProviderView: true),
                    ),
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
