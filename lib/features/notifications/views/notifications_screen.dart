import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/feedback/app_dialog.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/error_state.dart';
import '../../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../notifications/models/notification_model.dart';
import '../../../core/widgets/misc/app_icon.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/theme/app_palette.dart';

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
///
/// Two tabs: the inbox and the archive. Swipe a notification right to
/// archive it (or restore it from the archive) and left to delete it; long
/// press, or the select button, picks several at once.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)..addListener(_onTab);
  int _filter = 0;

  /// Notifications picked in select mode; null when not selecting.
  Set<String>? _selected;

  bool get _inArchive => _tabs.index == 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().load();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _onTab() {
    if (_tabs.indexIsChanging) return;
    setState(() => _selected = null);
    final controller = context.read<NotificationController>();
    if (_inArchive && !controller.hasLoadedArchived) controller.loadArchived();
  }

  Future<void> _reload() {
    final controller = context.read<NotificationController>();
    return _inArchive ? controller.loadArchived() : controller.load();
  }

  Future<void> _markAllRead() async {
    final controller = context.read<NotificationController>();
    final ok = await controller.markAllAsRead();
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(context, 'All notifications marked as read.');
    } else {
      AppSnackbar.error(context, controller.errorMessage ?? 'Unable to mark everything as read.');
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

  void _toggle(String id) => setState(() {
        final selected = _selected ??= <String>{};
        selected.contains(id) ? selected.remove(id) : selected.add(id);
      });

  /// Archives the notifications from the inbox, or restores them from the
  /// archive.
  Future<void> _move(Set<String> ids) async {
    if (ids.isEmpty) return;
    final controller = context.read<NotificationController>();
    final restoring = _inArchive;
    setState(() => _selected = null);
    final ok = restoring ? await controller.unarchive(ids) : await controller.archive(ids);
    if (!mounted) return;
    final what = ids.length == 1 ? 'Notification' : '${ids.length} notifications';
    if (ok) {
      AppSnackbar.success(context, restoring ? '$what moved back to your inbox.' : '$what archived.');
    } else {
      AppSnackbar.error(context, controller.errorMessage ?? 'Something went wrong. Please try again.');
    }
  }

  Future<bool> _confirmDelete(int count) => AppDialog.confirm(
        context,
        title: count == 1 ? 'Delete this notification?' : 'Delete $count notifications?',
        message: 'Deleted notifications are gone for good. Archive them instead to keep them out of the way.',
        confirmLabel: 'Delete',
        danger: true,
      );

  Future<void> _delete(Set<String> ids, {bool confirmed = false}) async {
    if (ids.isEmpty) return;
    if (!confirmed && !await _confirmDelete(ids.length)) return;
    if (!mounted) return;
    final controller = context.read<NotificationController>();
    setState(() => _selected = null);
    final ok = await controller.delete(ids);
    if (!mounted) return;
    if (ok) {
      AppSnackbar.success(context, ids.length == 1 ? 'Notification deleted.' : '${ids.length} notifications deleted.');
    } else {
      AppSnackbar.error(context, controller.errorMessage ?? 'Unable to delete those notifications.');
    }
  }

  PreferredSizeWidget _appBar(NotificationController controller, List<NotificationModel> visible) {
    final tabs = TabBar(
      controller: _tabs,
      tabs: [
        Tab(text: controller.unreadCount > 0 ? 'Inbox (${controller.unreadCount})' : 'Inbox'),
        const Tab(text: 'Archived'),
      ],
    );

    final selected = _selected;
    if (selected != null) {
      final allPicked = visible.isNotEmpty && visible.every((n) => selected.contains(n.id));
      return AppBar(
        leading: IconButton(
          tooltip: 'Cancel',
          icon: const AppIcon(AppIcons.close_rounded),
          onPressed: () => setState(() => _selected = null),
        ),
        title: Text(selected.isEmpty ? 'Select notifications' : '${selected.length} selected'),
        actions: [
          IconButton(
            tooltip: allPicked ? 'Clear selection' : 'Select all',
            icon: const AppIcon(AppIcons.checklist_rounded),
            onPressed: () => setState(() => _selected = allPicked ? <String>{} : visible.map((n) => n.id).toSet()),
          ),
          IconButton(
            tooltip: _inArchive ? 'Move to inbox' : 'Archive',
            icon: AppIcon(_inArchive ? AppIcons.unarchive_outlined : AppIcons.archive_outlined),
            onPressed: selected.isEmpty ? null : () => _move({...selected}),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: AppIcon(AppIcons.delete_outline_rounded, color: selected.isEmpty ? null : context.errorColor),
            onPressed: selected.isEmpty ? null : () => _delete({...selected}),
          ),
        ],
        bottom: tabs,
      );
    }

    return AppBar(
      title: const Text('Notifications'),
      actions: [
        if (!_inArchive && controller.unreadCount > 0)
          TextButton(
            onPressed: _markAllRead,
            child: Text('Mark all read', style: AppTextStyles.label.copyWith(color: context.accentInk)),
          ),
        if (visible.isNotEmpty)
          IconButton(
            tooltip: 'Select',
            icon: const AppIcon(AppIcons.checklist_rounded),
            onPressed: () => setState(() => _selected = <String>{}),
          ),
      ],
      bottom: tabs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationController>();
    final source = _inArchive ? controller.archived : controller.notifications;
    final visible = controller.withTypes(_filters[_filter].$2, archive: _inArchive);
    final loading = _inArchive ? controller.isLoadingArchived && source.isEmpty : controller.isLoading;
    final error = _inArchive ? controller.archiveError : controller.errorMessage;
    final failed = error != null && source.isEmpty && !loading;

    return PopScope(
      // Back leaves select mode before it leaves the screen.
      canPop: _selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _selected = null);
      },
      child: Scaffold(
        appBar: _appBar(controller, visible),
        body: SafeArea(
          child: failed
              ? ErrorState(message: error, onRetry: _reload)
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
                      child: loading
                          ? const Padding(
                              padding: EdgeInsets.all(AppSizes.pageHPad),
                              child: ShimmerCardList(itemHeight: 72),
                            )
                          : RefreshIndicator(
                              onRefresh: _reload,
                              child: visible.isEmpty
                                  ? ListView(
                                      padding: const EdgeInsets.only(top: AppSizes.xxl),
                                      children: [_empty()],
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(AppSizes.pageHPad),
                                      itemCount: visible.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                                      itemBuilder: (context, i) => _item(visible[i])
                                          .animate()
                                          .fadeIn(delay: Duration(milliseconds: i.clamp(0, 10) * 50), duration: 350.ms)
                                          .slideY(begin: 0.05, end: 0),
                                    ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _empty() {
    if (_inArchive) {
      return EmptyState(
        icon: AppIcons.archive_outlined,
        title: 'Nothing archived',
        message: _filter == 0
            ? 'Swipe a notification right to archive it and keep your inbox tidy.'
            : 'Archived notifications in this category will show up here.',
      );
    }
    return EmptyState(
      icon: AppIcons.notifications_none_rounded,
      title: _filter == 0 ? 'You\'re all caught up' : 'Nothing here',
      message:
          _filter == 0 ? 'New notifications will show up here.' : 'Notifications in this category will show up here.',
    );
  }

  /// A notification row: tap to open (or pick, while selecting), long press
  /// to start selecting, swipe right to archive or restore, left to delete.
  Widget _item(NotificationModel notification) {
    final selected = _selected;
    final row = _NotificationRow(
      notification: notification,
      selected: selected?.contains(notification.id),
      onTap: selected != null ? () => _toggle(notification.id) : () => _open(notification),
      onLongPress: () => _toggle(notification.id),
    );
    if (selected != null) return row;

    return Dismissible(
      key: ValueKey('notification-${notification.id}'),
      background: _SwipeAction(
        alignment: Alignment.centerLeft,
        icon: _inArchive ? AppIcons.unarchive_outlined : AppIcons.archive_outlined,
        label: _inArchive ? 'Move to inbox' : 'Archive',
        color: context.accentSoftColor,
        foreground: context.onAccentSoftColor,
      ),
      secondaryBackground: _SwipeAction(
        alignment: Alignment.centerRight,
        icon: AppIcons.delete_outline_rounded,
        label: 'Delete',
        color: context.errorColor.withValues(alpha: 0.14),
        foreground: context.errorColor,
      ),
      confirmDismiss: (direction) async => direction == DismissDirection.startToEnd || await _confirmDelete(1),
      onDismissed: (direction) => direction == DismissDirection.startToEnd
          ? _move({notification.id})
          : _delete({notification.id}, confirmed: true),
      child: row,
    );
  }
}

/// What a swipe will do, shown behind the notification as it slides.
class _SwipeAction extends StatelessWidget {
  final Alignment alignment;
  final AppIconData icon;
  final String label;
  final Color color;
  final Color foreground;

  const _SwipeAction({
    required this.alignment,
    required this.icon,
    required this.label,
    required this.color,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final leading = alignment == Alignment.centerLeft;
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppSizes.radiusLg)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: leading ? TextDirection.ltr : TextDirection.rtl,
        children: [
          AppIcon(icon, size: 20, color: foreground),
          const SizedBox(width: AppSizes.sm),
          Text(label, style: AppTextStyles.label.copyWith(color: foreground, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// Whether the row is picked; null when not selecting.
  final bool? selected;

  const _NotificationRow({
    required this.notification,
    required this.onTap,
    required this.onLongPress,
    this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final surfaceAltColor = isDark ? AppColors.surfaceAltDark : AppColors.surfaceAlt;
    final lineColor = isDark ? AppColors.lineDark : AppColors.line;
    final opens = notification.destination != null;

    final isSelected = selected ?? false;

    return Semantics(
      button: true,
      selected: selected,
      label: notification.isRead ? null : 'Unread notification',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: notification.isRead ? surfaceColor : surfaceAltColor,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: isSelected
                ? Border.all(color: context.accentInk, width: 2)
                : Border.all(color: lineColor.withValues(alpha: 0.5), width: 0.8),
            boxShadow: notification.isRead ? [] : AppSizes.shadowFor(context, level: ShadowLevel.sm),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selected != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isSelected ? context.accentInk : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? context.accentInk : context.textMutedColor, width: 2),
                    ),
                    child: isSelected
                        ? AppIcon(AppIcons.check_rounded, size: 13, color: Theme.of(context).colorScheme.surface)
                        : null,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
              ],
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
                    Text(Formatters.relative(notification.createdAt), style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 1.0, end: 1.3, duration: 1200.ms, curve: Curves.easeInOut)
              // A chevron only where there is somewhere to go.
              else if (opens)
                AppIcon(AppIcons.chevron_right_rounded, size: 16, color: context.textMutedColor),
            ],
          ),
        ),
      ),
    );
  }
}
