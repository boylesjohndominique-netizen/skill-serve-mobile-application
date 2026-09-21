import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../notifications/models/notification_model.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';

const Map<NotificationType, AppIconData> _typeIcons = {
  NotificationType.booking: AppIcons.calendar_month_rounded,
  NotificationType.message: AppIcons.chat_bubble_rounded,
  NotificationType.system: AppIcons.info_rounded,
  NotificationType.announcement: AppIcons.announcement_rounded,
  NotificationType.promo: AppIcons.local_offer_rounded,
  NotificationType.verification: AppIcons.verified_user_rounded,
  NotificationType.service: AppIcons.design_services_rounded,
};

/// Filters across the top of the feed. An empty type list means "everything".
const _filters = <(String, List<NotificationType>)>[
  ('All', []),
  ('Bookings', [NotificationType.booking]),
  ('Messages', [NotificationType.message]),
  ('Services', [NotificationType.service, NotificationType.verification]),
  ('Announcements', [NotificationType.announcement, NotificationType.promo]),
  ('System', [NotificationType.system]),
];

/// Shared notifications feed for both Client and Service Provider.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().load();
    });
  }

  Future<void> _reload() => context.read<NotificationController>().load();

  Future<void> _markAllRead() async {
    final controller = context.read<NotificationController>();
    final ok = await controller.markAllAsRead();
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(context, 'All notifications marked as read.');
    } else {
      AppSnackbar.error(
          context, controller.errorMessage ?? 'Unable to mark everything as read.');
    }
  }

  /// Marks the notification read, then opens what it is about when it points
  /// somewhere the app can go.
  Future<void> _open(NotificationModel notification) async {
    final controller = context.read<NotificationController>();
    await controller.markAsRead(notification.id);
    if (!mounted) return;

    final destination = notification.destination;
    if (destination != null) context.push(destination);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationController>();
    final failed = controller.errorMessage != null && controller.notifications.isEmpty;
    final visible = controller.withTypes(_filters[_filter].$2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (controller.unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read',
                  style: AppTextStyles.label.copyWith(color: AppColors.secondary)),
            ),
        ],
      ),
      body: SafeArea(
        child: failed
            ? ErrorState(message: controller.errorMessage!, onRetry: _reload)
            : Column(
                children: [
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.pageHPad),
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => Center(
                        child: ChoiceChip(
                          label: Text(_filters[i].$1),
                          selected: _filter == i,
                          selectedColor: AppColors.secondary,
                          showCheckmark: false,
                          labelStyle: AppTextStyles.label.copyWith(
                            color: _filter == i ? AppColors.primary : null,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setState(() => _filter = i),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: controller.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(AppSizes.pageHPad),
                            child: ShimmerCardList(itemHeight: 72),
                          )
                        : RefreshIndicator(
                            onRefresh: _reload,
                            child: visible.isEmpty
                                ? ListView(
                                    padding: const EdgeInsets.only(top: AppSizes.xxl),
                                    children: [
                                      EmptyState(
                                        icon: AppIcons.notifications_none_rounded,
                                        title: _filter == 0
                                            ? 'You\'re all caught up'
                                            : 'Nothing here',
                                        message: _filter == 0
                                            ? 'New notifications will show up here.'
                                            : 'Notifications in this category will show up here.',
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(AppSizes.pageHPad),
                                    itemCount: visible.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: AppSizes.sm),
                                    itemBuilder: (context, i) => _NotificationRow(
                                      notification: visible[i],
                                      onTap: () => _open(visible[i]),
                                    )
                                        .animate()
                                        .fadeIn(
                                            delay: Duration(
                                                milliseconds: i.clamp(0, 10) * 50),
                                            duration: 350.ms)
                                        .slideY(begin: 0.05, end: 0),
                                  ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationRow({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final surfaceAltColor = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;
    final opens = notification.destination != null;

    return Semantics(
      button: true,
      label: notification.isRead ? null : 'Unread notification',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: notification.isRead ? surfaceColor : surfaceAltColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
            boxShadow: notification.isRead
                ? []
                : AppSizes.shadowFor(context, level: ShadowLevel.sm),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: AppIcon(
                  _typeIcons[notification.type] ?? AppIcons.notifications_rounded,
                  size: 16,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.title, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 2),
                    Text(notification.message, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 4),
                    Text(Formatters.relative(notification.createdAt),
                        style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                      color: AppColors.secondary, shape: BoxShape.circle),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 1.0, end: 1.3, duration: 1200.ms, curve: Curves.easeInOut)
              // A chevron only where there is somewhere to go.
              else if (opens)
                const AppIcon(AppIcons.chevron_right_rounded,
                    size: 16, color: AppColors.neutral300),
            ],
          ),
        ),
      ),
    );
  }
}
