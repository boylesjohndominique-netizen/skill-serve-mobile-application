enum NotificationType {
  booking,
  message,
  system,
  announcement,
  promo,
  verification,
  service,
}

/// One entry in the notification feed.
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;

  /// The notification's own payload, kept so a tap can open what it is about
  /// (`booking_id`, `ticket_id`, `service_id`, `announcement_id`, …). The API
  /// whitelists which keys survive, so this is small and predictable.
  final Map<String, dynamic> data;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data = const {},
  });

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        title: title,
        message: message,
        type: type,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        data: data,
      );

  /// Where tapping this notification should go, or null when it is purely
  /// informational (an announcement, a security notice).
  ///
  /// Only routes that exist are returned — a notification must never strand the
  /// user on a screen the app cannot build.
  String? get destination {
    final bookingId = _id('booking_id');
    final ticketId = _id('ticket_id');
    final serviceId = _id('service_id');

    // A message is about a conversation, which is addressed by its booking.
    if (type == NotificationType.message && bookingId != null) {
      return '/chat-conversation/$bookingId';
    }
    if (bookingId != null) return '/booking-details/$bookingId';
    // A decision on the provider's verification opens where they can act on it.
    if (_rawType == 'provider_verification') return '/verification-status';
    // A decision on the National ID opens the identity screen.
    if (_rawType == 'identity_verification') return '/identity-verification';
    // The outcome of something the user reported.
    if (_rawType == 'report_update' || data['report_id'] != null) return '/my-reports';
    if (ticketId != null) return '/support/tickets/$ticketId';
    // A provider's own service, which is the only service screen a tap can open.
    if (type == NotificationType.service && serviceId != null) {
      return '/edit-service/$serviceId';
    }
    return null;
  }

  /// The API's own `type` (e.g. `provider_verification`), kept in [data].
  String get _rawType => (data['type'] ?? '').toString();

  String? _id(String key) {
    final value = data[key];
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: (json['id'] ?? json['notification_id']).toString(),
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        type: typeFromApi(json['type'] as String?),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
            DateTime.now(),
        isRead: json['read_at'] != null || json['status'] == 'read',
        data: json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : const {},
      );

  /// Maps backend notification types (e.g. `service_moderation`,
  /// `support_ticket_response`, `booking_status`) onto the feed's categories.
  /// Unknown types fall back to [NotificationType.system] instead of failing
  /// the feed.
  static NotificationType typeFromApi(String? type) {
    final value = type ?? '';
    for (final known in NotificationType.values) {
      if (known.name == value) return known;
    }
    if (value.startsWith('service')) return NotificationType.service;
    // Message-ish types are matched first: `booking_message` is a chat message
    // about a booking, and belongs with Messages — the server gates it with the
    // "Messages" preference, and tapping it should open the conversation.
    // Support replies are staff writing to the user, gated the same way.
    if (value.contains('message') || value.startsWith('support_ticket')) {
      return NotificationType.message;
    }
    if (value.contains('booking') || value.contains('dispute')) return NotificationType.booking;
    if (value.contains('verification')) return NotificationType.verification;
    return NotificationType.system;
  }
}
