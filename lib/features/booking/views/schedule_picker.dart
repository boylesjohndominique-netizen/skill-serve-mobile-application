import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../provider/models/provider_availability_model.dart';

/// The start times a customer may request with a provider — shared by the
/// booking wizard and rescheduling, so both offer exactly what the API's
/// hours check accepts.
class BookingSlots {
  BookingSlots._();

  /// Start times are offered every half hour inside the provider's window.
  static const stepMinutes = 30;

  /// The working day offered when a provider publishes no weekly hours at
  /// all — the API leaves those bookings unrestricted, so any sensible time
  /// works.
  static const openDayStartMinutes = 8 * 60;
  static const openDayEndMinutes = 17 * 60;

  /// The provider's published window for [date], or null when they publish
  /// no hours or do not work that weekday.
  static ProviderAvailabilityModel? windowFor(
    List<ProviderAvailabilityModel> availability,
    DateTime date,
  ) {
    // `day_of_week` is 0 = Sunday, while Dart's Sunday is 7.
    return availability.where((w) => w.dayOfWeek == date.weekday % 7).firstOrNull;
  }

  /// True when the provider publishes hours but none for [date].
  static bool closedOn(List<ProviderAvailabilityModel> availability, DateTime date) =>
      availability.isNotEmpty && windowFor(availability, date) == null;

  /// Start times (minutes from midnight) that still leave room for
  /// [durationMinutes] inside the day's window — the same rule the API
  /// enforces, so a pick cannot be refused for being out of hours.
  static List<int> options(
    List<ProviderAvailabilityModel> availability,
    DateTime date,
    int durationMinutes,
  ) {
    if (closedOn(availability, date)) return const [];

    final window = windowFor(availability, date);
    final start = window == null ? openDayStartMinutes : minutes(window.startTime);
    final end = window == null ? openDayEndMinutes : minutes(window.endTime);

    final slots = <int>[];
    for (var at = start; at + durationMinutes <= end; at += stepMinutes) {
      slots.add(at);
    }
    // A window shorter than the service still offers its opening time; the
    // API decides, and refusing to show anything would look like a bug.
    if (slots.isEmpty && end > start) slots.add(start);
    return slots;
  }

  /// The wall-clock start for [slot] on [date].
  static DateTime at(DateTime date, int slot) =>
      DateTime(date.year, date.month, date.day).add(Duration(minutes: slot));

  static int minutes(String hhmm) {
    final parts = hhmm.split(':');
    return ((int.tryParse(parts.first) ?? 0) * 60) +
        (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }

  static String label(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final suffix = hour < 12 ? 'AM' : 'PM';
    final display = hour % 12 == 0 ? 12 : hour % 12;
    return '$display:${minute.toString().padLeft(2, '0')} $suffix';
  }
}

/// A date field over the provider's bookable time slots for that day.
///
/// Stateless: the screen owns the chosen [date] and [selectedSlot] and hears
/// about changes through [onPickDate] and [onSlotSelected].
class SchedulePicker extends StatelessWidget {
  final List<ProviderAvailabilityModel> availability;

  /// How the provider is named in the "does not work on …" hint.
  final String providerName;
  final DateTime date;
  final int? selectedSlot;
  final int durationMinutes;
  final VoidCallback onPickDate;
  final ValueChanged<int> onSlotSelected;

  const SchedulePicker({
    super.key,
    required this.availability,
    required this.providerName,
    required this.date,
    required this.selectedSlot,
    required this.durationMinutes,
    required this.onPickDate,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slots = BookingSlots.options(availability, date, durationMinutes);
    final window = BookingSlots.windowFor(availability, date);
    final fieldColor = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSizes.sm),
        InkWell(
          onTap: onPickDate,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 14),
            decoration: BoxDecoration(
              color: fieldColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                const AppIcon(AppIcons.calendar_today_rounded, size: 18, color: AppColors.secondary),
                const SizedBox(width: AppSizes.sm),
                Text(Formatters.dateShort(date), style: AppTextStyles.bodyLarge),
                const Spacer(),
                const AppIcon(AppIcons.chevron_right_rounded, size: 18, color: AppColors.neutral300),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.xl),
        Text('Available time slots', style: AppTextStyles.titleMedium),
        const SizedBox(height: 4),
        Text(
          BookingSlots.closedOn(availability, date)
              ? '$providerName does not work on ${ProviderAvailabilityModel.dayNames[date.weekday % 7]}s. Pick another date.'
              : window != null
                  ? 'Published hours: ${window.label}.'
                  : 'This provider has not published weekly hours, so any time in the working day can be requested.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSizes.sm),
        if (slots.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: fieldColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                const AppIcon(AppIcons.event_busy_rounded, size: 18, color: AppColors.neutral400),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text('No slots on this date — choose another day.',
                      style: AppTextStyles.bodyMedium),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < slots.length; i++)
                ChoiceChip(
                  label: Text(BookingSlots.label(slots[i])),
                  selected: selectedSlot == slots[i],
                  selectedColor: AppColors.secondary,
                  labelStyle: AppTextStyles.label.copyWith(
                    color: selectedSlot == slots[i] ? AppColors.primary : null,
                    fontWeight: FontWeight.w600,
                  ),
                  showCheckmark: false,
                  onSelected: (_) => onSlotSelected(slots[i]),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 150 + i.clamp(0, 10) * 40), duration: 300.ms)
                    .slideX(begin: 0.08, end: 0),
            ],
          ),
      ],
    );
  }
}
