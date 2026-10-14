/// Addresses a chat thread in the app: a booking's chat by its booking id (as
/// it always was, so existing routes and notifications keep working), or a
/// conversation before booking as `inquiry-<id>`.
abstract final class ChatThread {
  static const _inquiryPrefix = 'inquiry-';

  /// The key of the conversation before booking with id [inquiryId].
  static String inquiry(Object inquiryId) => '$_inquiryPrefix$inquiryId';

  static bool isInquiry(String key) => key.startsWith(_inquiryPrefix);

  /// The thread from an API payload carrying `booking_id` or `inquiry_id`
  /// (a pushed message, a notification); null when it has neither.
  static String? fromIds({Object? bookingId, Object? inquiryId}) {
    if (inquiryId != null && '$inquiryId'.isNotEmpty) return inquiry(inquiryId);
    if (bookingId != null && '$bookingId'.isNotEmpty) return '$bookingId';
    return null;
  }

  /// `/bookings/{id}/messages` or `/inquiries/{id}/messages` under the client API.
  static String messagesPath(String key) => isInquiry(key)
      ? '/client/v1/inquiries/${key.substring(_inquiryPrefix.length)}/messages'
      : '/client/v1/bookings/$key/messages';

  /// The presence channel for "in this chat" and typing hints.
  static String presenceChannel(String key) => isInquiry(key)
      ? 'inquiry-chat.${key.substring(_inquiryPrefix.length)}'
      : 'booking-chat.$key';

  /// The app route that opens the thread.
  static String route(String key) => '/chat-conversation/$key';
}
