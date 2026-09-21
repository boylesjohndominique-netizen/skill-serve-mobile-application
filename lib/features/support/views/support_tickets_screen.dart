import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../controllers/support_controller.dart';
import '../models/support_ticket_model.dart';
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

/// The support inbox: every ticket the account has raised.
class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportController>().loadTickets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reload() => context.read<SupportController>().loadTickets();

  @override
  Widget build(BuildContext context) {
    final support = context.watch<SupportController>();
    final failed = support.errorMessage != null && support.tickets.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        bottom: failed
            ? null
            : TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Open (${support.openTickets.length})'),
                  Tab(text: 'Resolved (${support.resolvedTickets.length})'),
                ],
              ),
      ),
      body: SafeArea(
        child: support.isLoading
            ? const Padding(
                padding: EdgeInsets.all(AppSizes.pageHPad),
                child: ShimmerCardList(itemHeight: 96),
              )
            : failed
                ? ErrorState(message: support.errorMessage!, onRetry: _reload)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _TicketList(
                        tickets: support.openTickets,
                        onRefresh: _reload,
                        emptyTitle: 'No open tickets',
                        emptyMessage:
                            'Need a hand? Start a ticket and our support team will get back to you.',
                      ),
                      _TicketList(
                        tickets: support.resolvedTickets,
                        onRefresh: _reload,
                        emptyTitle: 'Nothing resolved yet',
                        emptyMessage: 'Tickets our team has closed will be kept here.',
                      ),
                    ],
                  ),
      ),
      floatingActionButton: failed
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/support/new'),
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.primary,
              icon: const AppIcon(AppIcons.add_rounded, size: 18, color: AppColors.primary),
              label: const Text('New ticket'),
            ),
    );
  }
}

class _TicketList extends StatelessWidget {
  final List<SupportTicketModel> tickets;
  final Future<void> Function() onRefresh;
  final String emptyTitle;
  final String emptyMessage;

  const _TicketList({
    required this.tickets,
    required this.onRefresh,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: tickets.isEmpty
          ? ListView(
              padding: const EdgeInsets.only(top: AppSizes.xxl),
              children: [
                EmptyState(
                  icon: AppIcons.support_agent_rounded,
                  title: emptyTitle,
                  message: emptyMessage,
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSizes.pageHPad),
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSizes.md),
              itemBuilder: (context, i) => _TicketCard(ticket: tickets[i])
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: i.clamp(0, 8) * 60), duration: 350.ms)
                  .slideY(begin: 0.06, end: 0),
            ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final SupportTicketModel ticket;
  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;

    return InkWell(
      onTap: () => context.push('/support/tickets/${ticket.id}'),
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
          boxShadow: AppSizes.shadowFor(context, level: ShadowLevel.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(ticket.subject,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: AppSizes.sm),
                StatusBadge.fromStatus(ticket.status.name),
              ],
            ),
            const SizedBox(height: 2),
            Text(ticket.categoryLabel, style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSizes.sm),
            Text(ticket.description,
                style: AppTextStyles.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
            Divider(height: AppSizes.lg, color: lineColor),
            Row(
              children: [
                if (ticket.ticketNumber.isNotEmpty)
                  Text(ticket.ticketNumber, style: AppTextStyles.monoSm),
                const Spacer(),
                Text('Opened ${Formatters.relative(ticket.createdAt)}',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
