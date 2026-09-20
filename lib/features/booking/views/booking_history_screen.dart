import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/booking_controller.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cards/booking_card.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../models/booking_model.dart';
import '../../../core/constants/app_icons.dart';

/// Client's booking list, filterable by status. [embedded] hides the
/// AppBar when hosted inside [ClientShell]'s bottom-nav tab.
class BookingHistoryScreen extends StatefulWidget {
  final bool embedded;
  const BookingHistoryScreen({super.key, this.embedded = false});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: _filters.length, vsync: this);

  /// An empty status list means "every booking".
  static const _filters = <(String, List<BookingStatus>)>[
    ('All', []),
    ('Pending', [BookingStatus.pending]),
    ('Confirmed', [BookingStatus.confirmed]),
    ('In Progress', [BookingStatus.inProgress]),
    ('Completed', [BookingStatus.completed]),
    ('Cancelled', [BookingStatus.cancelled]),
    ('Disputed', [BookingStatus.disputed]),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingController>().loadClientBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reload() => context.read<BookingController>().loadClientBookings();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingController>();
    final failed = controller.errorMessage != null && controller.bookings.isEmpty;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.pageHPad, AppSizes.lg, AppSizes.pageHPad, 0),
          child: Text('My Bookings', style: AppTextStyles.displayMedium)
              .animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
        ),
        if (failed)
          Expanded(child: ErrorState(message: controller.errorMessage!, onRetry: _reload))
        else ...[
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final f in _filters) Tab(text: f.$1)],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (final f in _filters)
                  _BookingList(
                    bookings: controller.withStatus(f.$2),
                    loading: controller.isLoading,
                    onRefresh: _reload,
                  ),
              ],
            ),
          ),
        ],
      ],
    );

    if (widget.embedded) return Scaffold(body: SafeArea(child: content));
    return Scaffold(appBar: AppBar(title: const Text('My Bookings')), body: SafeArea(child: content));
  }
}

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final bool loading;
  final Future<void> Function() onRefresh;

  const _BookingList({required this.bookings, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(padding: EdgeInsets.all(AppSizes.pageHPad), child: ShimmerCardList());
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: bookings.isEmpty
          // A scrollable empty state keeps pull-to-refresh reachable.
          ? ListView(
              padding: const EdgeInsets.only(top: AppSizes.xxl),
              children: const [
                EmptyState(
                  icon: AppIcons.calendar_month_outlined,
                  title: 'No bookings here',
                  message: 'Bookings in this category will show up here.',
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.pageHPad),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
              itemBuilder: (context, i) => BookingCard(
                booking: bookings[i],
                onTap: () => context.push('/booking-details/${bookings[i].id}'),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                  .slideY(begin: 0.06, end: 0),
            ),
    );
  }
}
