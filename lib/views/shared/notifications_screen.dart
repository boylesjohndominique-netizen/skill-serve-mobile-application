import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/notification_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback/empty_state.dart';
import '../../core/widgets/feedback/shimmer_placeholder.dart';
import '../../models/notification_model.dart';

const Map<NotificationType, IconData> _typeIcons = {
  NotificationType.booking: Icons.calendar_month_rounded,
  NotificationType.message: Icons.chat_bubble_rounded,
  NotificationType.system: Icons.info_rounded,
  NotificationType.promo: Icons.local_offer_rounded,
  NotificationType.verification: Icons.verified_user_rounded,
};

/// Shared notifications feed for both Client and Service Provider.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: SafeArea(
        child: controller.isLoading
            ? const Padding(padding: EdgeInsets.all(AppSizes.pageHPad), child: ShimmerCardList(itemHeight: 72))
            : controller.notifications.isEmpty
                ? const EmptyState(icon: Icons.notifications_none_rounded, title: 'You\'re all caught up', message: 'New notifications will show up here.')
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.pageHPad),
                    itemCount: controller.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
                    itemBuilder: (context, i) {
                      final n = controller.notifications[i];
                      return InkWell(
                        onTap: () => controller.markAsRead(n.id),
                        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                        child: Container(
                          padding: const EdgeInsets.all(AppSizes.md),
                          decoration: BoxDecoration(
                            color: n.isRead ? AppColors.surface : AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppSizes.radiusMd)),
                                child: Icon(_typeIcons[n.type] ?? Icons.notifications_rounded, size: 16, color: AppColors.secondary),
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title, style: AppTextStyles.titleMedium),
                                    const SizedBox(height: 2),
                                    Text(n.message, style: AppTextStyles.bodyMedium),
                                    const SizedBox(height: 4),
                                    Text(Formatters.relative(n.createdAt), style: AppTextStyles.bodySmall),
                                  ],
                                ),
                              ),
                              if (!n.isRead)
                                Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4), decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
