import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/api_error.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/loading_state.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../models/provider_availability_model.dart';
import '../services/provider_service_service.dart';
import '../../../core/theme/app_palette.dart';

/// The provider's weekly hours: which days they work, between which times,
/// and whether they are taking new bookings at all.
///
/// Clients see this on the public profile, discovery filters by it, and the
/// booking flow refuses times outside a published window — so the screen
/// spells out what leaving the schedule empty means.
class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  final _service = ProviderServiceService();

  /// One editable row per weekday, indexed 0 (Sunday) … 6 (Saturday).
  final _windows = List<ProviderAvailabilityModel?>.filled(7, null);

  bool _acceptingBookings = true;
  bool _loading = true;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final schedule = await _service.getMyAvailability();
      if (!mounted) return;
      setState(() {
        _acceptingBookings = schedule.isAcceptingBookings;
        for (var day = 0; day < 7; day++) {
          _windows[day] = schedule.windowFor(day);
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final schedule = await _service.updateMyAvailability(
        isAcceptingBookings: _acceptingBookings,
        availability: [
          for (final window in _windows)
            if (window != null) window,
        ],
      );
      if (!mounted) return;
      setState(() {
        _acceptingBookings = schedule.isAcceptingBookings;
        for (var day = 0; day < 7; day++) {
          _windows[day] = schedule.windowFor(day);
        }
        _saving = false;
      });
      AppSnackbar.success(context, 'Availability saved.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(
        context,
        apiErrorMessage(error, 'We could not save your availability.'),
      );
    }
  }

  void _toggleDay(int day, bool working) {
    setState(() {
      // A newly opened day starts on the common 9-to-5 window.
      _windows[day] = working
          ? ProviderAvailabilityModel(dayOfWeek: day, startTime: '09:00', endTime: '17:00')
          : null;
    });
  }

  Future<void> _pickTime(int day, {required bool isStart}) async {
    final window = _windows[day];
    if (window == null) return;

    final current = _parse(isStart ? window.startTime : window.endTime);
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null || !mounted) return;

    final value = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final updated = isStart
        ? window.copyWith(startTime: value)
        : window.copyWith(endTime: value);

    if (_minutes(updated.endTime) <= _minutes(updated.startTime)) {
      AppSnackbar.error(context, 'The end time must be later than the start time.');
      return;
    }

    setState(() => _windows[day] = updated);
  }

  TimeOfDay _parse(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
  }

  int _minutes(String time) {
    final parts = time.split(':');
    return ((int.tryParse(parts.first) ?? 0) * 60) +
        (parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0);
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Availability')),
        body: ErrorState(message: 'We could not load your availability.', onRetry: _load),
      );
    }
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Availability')),
        body: const LoadingState(),
      );
    }

    final publishedDays = _windows.where((window) => window != null).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Availability')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.pageHPad),
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _acceptingBookings,
              onChanged: (value) => setState(() => _acceptingBookings = value),
              title: Text('Accepting new bookings', style: AppTextStyles.titleMedium),
              subtitle: Text(
                _acceptingBookings
                    ? 'Clients can request bookings with you.'
                    : 'You stay listed, but clients cannot book you.',
                style: AppTextStyles.bodySmall,
              ),
            ).animate().fadeIn(duration: 300.ms),
            const Divider(height: AppSizes.xl),
            Text('Weekly hours', style: AppTextStyles.titleLarge),
            const SizedBox(height: 4),
            Text(
              publishedDays == 0
                  ? 'You publish no hours, so clients can book you at any time.'
                  : 'Clients can only book you inside these hours.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSizes.md),
            for (var day = 0; day < 7; day++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: _DayRow(
                  day: day,
                  window: _windows[day],
                  onToggle: (working) => _toggleDay(day, working),
                  onPickStart: () => _pickTime(day, isStart: true),
                  onPickEnd: () => _pickTime(day, isStart: false),
                )
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 60 * day), duration: 300.ms)
                    .slideY(begin: 0.05, end: 0),
              ),
            const SizedBox(height: AppSizes.lg),
            PrimaryButton(
              label: 'Save availability',
              icon: AppIcons.check_rounded,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: AppSizes.xxl),
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final int day;
  final ProviderAvailabilityModel? window;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  const _DayRow({
    required this.day,
    required this.window,
    required this.onToggle,
    required this.onPickStart,
    required this.onPickEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final working = window != null;
    final dayName = ProviderAvailabilityModel.dayNames[day];

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: (isDark ? AppColors.lineDark : AppColors.line).withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(dayName, style: AppTextStyles.titleMedium)),
              Switch.adaptive(
                value: working,
                onChanged: onToggle,
              ),
            ],
          ),
          if (working) ...[
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'Starts',
                    time: window!.startTime,
                    onTap: onPickStart,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _TimeButton(
                    label: 'Ends',
                    time: window!.endTime,
                    onTap: onPickEnd,
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

class _TimeButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeButton({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: '$label at $time, change',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Row(
            children: [
              AppIcon(AppIcons.schedule_rounded, size: 15, color: context.accentInk),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.caption),
                    Text(time, style: AppTextStyles.label.copyWith(fontWeight: FontWeight.w700)),
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
