enum NotificationType { booking, message, system, promo, verification }

/// Mirrors the `notifications` table.
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['notification_id'].toString(),
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        type: NotificationType.values.byName(json['type'] as String? ?? 'system'),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        isRead: json['status'] == 'read',
      );
}
