enum NotificationType { booking, message, system, promo, verification, service }

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
        id: (json['id'] ?? json['notification_id']).toString(),
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        type: typeFromApi(json['type'] as String?),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        isRead: json['read_at'] != null || json['status'] == 'read',
      );

  /// Maps backend notification types (e.g. `service_moderation`,
  /// `support_ticket_response`) onto the feed's icon categories. Unknown
  /// types fall back to [NotificationType.system] instead of failing the feed.
  static NotificationType typeFromApi(String? type) {
    final value = type ?? '';
    for (final known in NotificationType.values) {
      if (known.name == value) return known;
    }
    if (value.startsWith('service')) return NotificationType.service;
    if (value.contains('booking')) return NotificationType.booking;
    if (value.contains('message')) return NotificationType.message;
    if (value.contains('verification')) return NotificationType.verification;
    return NotificationType.system;
  }
}
