import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/booking_controller.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/cards/booking_card.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../models/booking_model.dart';

/// Client's booking list, filterable by status. [embedded] hides the
/// AppBar when hosted inside [ClientShell]'s bottom-nav tab.
class BookingHistoryScreen extends StatefulWidget {
  final bool embedded;
  const BookingHistoryScreen({super.key, this.embedded = false});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  final _filters = const [
    ('All', null),
    ('Upcoming', [BookingStatus.pending, BookingStatus.confirmed]),
    ('Ongoing', [BookingStatus.inProgress]),
    ('Past', [BookingStatus.completed, BookingStatus.cancelled]),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingController>().loadClientBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BookingController>();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.pageHPad, AppSizes.lg, AppSizes.pageHPad, 0),
          child: Text('My Bookings', style: AppTextStyles.displayMedium),
        ),
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
                  bookings: f.$2 == null ? controller.bookings : controller.bookings.where((b) => f.$2!.contains(b.status)).toList(),
                  loading: controller.isLoading,
                ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) return Scaffold(body: SafeArea(child: content));
    return Scaffold(appBar: AppBar(title: const Text('My Bookings')), body: SafeArea(child: content));
  }
}

class _BookingList extends StatelessWidget {
  final List<BookingModel> bookings;
  final bool loading;
  const _BookingList({required this.bookings, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(padding: EdgeInsets.all(AppSizes.pageHPad), child: ShimmerCardList());
    }
    if (bookings.isEmpty) {
      return const EmptyState(icon: Icons.calendar_month_outlined, title: 'No bookings here', message: 'Bookings in this category will show up here.');
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSizes.pageHPad),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
      itemBuilder: (context, i) => BookingCard(
        booking: bookings[i],
        onTap: () => context.push('/booking-details/${bookings[i].id}'),
      ),
    );
  }
}
