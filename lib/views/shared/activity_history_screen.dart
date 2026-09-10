import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../core/widgets/misc/app_icon.dart';
import '../../core/widgets/misc/status_badge.dart';
import '../../models/booking_model.dart';
import '../../models/report_model.dart';
import '../../services/booking_service.dart';
import '../../services/report_service.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  final _bookingService = BookingService();
  final _reportService = ReportService();
  List<BookingModel> _bookings = const [];
  List<ReportModel> _reports = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<AuthController>().currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final bookings = user.role.name == 'provider'
        ? await _bookingService.getProviderBookings()
        : await _bookingService.getClientBookings();
    final reports = await _reportService.getMyReports();
    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _reports = reports;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Activity History')),
      body: SafeArea(
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pageHPad),
                child: ShimmerCardList(itemHeight: 78))
            : user == null
                ? const EmptyState(
                    icon: AppIcons.history_rounded,
                    title: 'Sign in to view activity',
                    message:
                        'Your account activity will appear here after you sign in.')
                : (_bookings.isEmpty && _reports.isEmpty)
                    ? const EmptyState(
                        icon: AppIcons.history_rounded,
                        title: 'No activity yet',
                        message: 'Your bookings and reports will appear here.')
                    : ListView(
                        padding: const EdgeInsets.all(AppSizes.pageHPad),
                        children: [
                          _ActivityRow(
                            icon: AppIcons.person_rounded,
                            title: 'Account created',
                            subtitle: 'Your SkillServe account was created',
                            date: user.createdAt,
                          ),
                          for (final booking in _bookings)
                            _ActivityRow(
                              icon: AppIcons.calendar_month_rounded,
                              title: booking.serviceTitle,
                              subtitle:
                                  '${booking.providerName} · booking ${booking.id}',
                              date: booking.bookingDate,
                              badge:
                                  StatusBadge.fromStatus(booking.status.name),
                              onTap: () => context
                                  .push('/booking-details/${booking.id}'),
                            ),
                          for (final report in _reports)
                            _ActivityRow(
                              icon: AppIcons.flag_outlined,
                              title: report.reason,
                              subtitle: 'Report ${report.id}',
                              date: report.createdAt,
                              badge: StatusBadge.fromStatus(report.status.name),
                            ),
                        ],
                      ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final AppIconData icon;
  final String title;
  final String subtitle;
  final DateTime date;
  final Widget? badge;
  final VoidCallback? onTap;

  const _ActivityRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.date,
      this.badge,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTextStyles.bodySmall),
                const SizedBox(height: 6),
                if (badge != null) badge!,
                const SizedBox(height: 4),
                Text(Formatters.relative(date), style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          if (onTap != null)
            const AppIcon(AppIcons.chevron_right_rounded, size: 18),
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
