import 'chat_thread.dart';

/// One message on a booking, as `BookingMessage` returns it.
class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String content;
  final DateTime sentAt;
  final DateTime? readAt;

  /// The attached photo — private, read with the user's token — or null.
  final String? imageUrl;

  /// The picked photo on this phone, shown while the message is sending (or
  /// after it failed, so a retry can upload it again).
  final String? localImagePath;

  /// True while an optimistically shown message has not been accepted by the
  /// API yet — the bubble renders as "Sending…" until the real one replaces it.
  final bool isPending;

  /// True when the send failed, so the bubble can offer a retry.
  final bool hasFailed;

  const MessageModel({
    required this.id,
    required this.senderId,
    this.senderName = '',
    this.receiverId = '',
    required this.content,
    required this.sentAt,
    this.readAt,
    this.imageUrl,
    this.localImagePath,
    this.isPending = false,
    this.hasFailed = false,
  });

  bool get isRead => readAt != null;

  bool get hasImage => imageUrl != null || localImagePath != null;

  /// One line for the inbox — the text, or "📷 Photo" for a photo alone
  /// (the same wording the API uses).
  String get preview => content.isNotEmpty ? content : (hasImage ? '📷 Photo' : '');

  MessageModel copyWith({bool? isPending, bool? hasFailed}) => MessageModel(
        id: id,
        senderId: senderId,
        senderName: senderName,
        receiverId: receiverId,
        content: content,
        sentAt: sentAt,
        readAt: readAt,
        imageUrl: imageUrl,
        localImagePath: localImagePath,
        isPending: isPending ?? this.isPending,
        hasFailed: hasFailed ?? this.hasFailed,
      );

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final sender = json['sender'] as Map<String, dynamic>?;
    final receiver = json['receiver'] as Map<String, dynamic>?;

    return MessageModel(
      id: json['id'].toString(),
      senderId: sender?['id']?.toString() ?? '',
      senderName: sender?['name'] as String? ?? '',
      receiverId: receiver?['id']?.toString() ?? '',
      content: json['content'] as String? ?? '',
      sentAt: _date(json['created_at']) ?? DateTime.now(),
      readAt: _date(json['read_at']),
      imageUrl: json['image_url'] as String?,
    );
  }

  static DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;
}

/// One thread in the Messages inbox, as `Conversation` returns it: a
/// booking's chat, or a conversation with a provider before booking.
class ConversationModel {
  /// Addresses the thread everywhere in the app ([ChatThread]).
  final String threadKey;

  /// The booking for a booking chat; empty before booking.
  final String bookingId;
  final String bookingNumber;
  final String bookingStatus;
  final String serviceTitle;

  /// The other party — a provider's business name for a customer, the
  /// customer's name for a provider.
  final String participantId;
  final String participantName;
  final String? participantAvatar;

  /// The provider's public profile id when the other party is the provider
  /// (the customer's view); null on the provider's side.
  final String? providerProfileId;

  final String lastMessage;

  /// Whether the signed-in account sent [lastMessage], so the list can
  /// prefix it with "You: ".
  final bool lastMessageIsMine;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ConversationModel({
    required this.threadKey,
    this.bookingId = '',
    this.bookingNumber = '',
    this.bookingStatus = '',
    this.serviceTitle = '',
    this.participantId = '',
    this.participantName = '',
    this.participantAvatar,
    this.providerProfileId,
    this.lastMessage = '',
    this.lastMessageIsMine = false,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  bool get isInquiry => ChatThread.isInquiry(threadKey);

  /// What the conversation is about, under the name: the booked service, or
  /// that it comes before any booking.
  String get topic => isInquiry ? 'Before booking' : serviceTitle;

  /// What the inbox row shows under the name.
  String get preview =>
      lastMessage.isEmpty ? 'No messages yet' : (lastMessageIsMine ? 'You: $lastMessage' : lastMessage);

  /// Everything a row can be matched against by the search box.
  bool matches(String query) {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return true;
    return participantName.toLowerCase().contains(term) ||
        serviceTitle.toLowerCase().contains(term) ||
        bookingNumber.toLowerCase().contains(term) ||
        lastMessage.toLowerCase().contains(term);
  }

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final counterpart = json['counterpart'] as Map<String, dynamic>?;
    final last = json['last_message'] as Map<String, dynamic>?;

    final isInquiry = json['kind'] == 'inquiry';
    return ConversationModel(
      threadKey: isInquiry ? ChatThread.inquiry(json['inquiry_id']) : json['booking_id'].toString(),
      bookingId: isInquiry ? '' : json['booking_id'].toString(),
      bookingNumber: json['booking_number'] as String? ?? '',
      bookingStatus: json['booking_status'] as String? ?? '',
      serviceTitle: json['service_title'] as String? ?? '',
      participantId: counterpart?['id']?.toString() ?? '',
      participantName: counterpart?['name'] as String? ?? '',
      participantAvatar: counterpart?['profile_picture'] as String?,
      providerProfileId: counterpart?['provider_id']?.toString(),
      lastMessage: last?['content'] as String? ?? '',
      lastMessageIsMine: last?['is_mine'] == true,
      lastMessageAt: MessageModel._date(json['last_message_at']),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  ConversationModel copyWith({
    int? unreadCount,
    String? lastMessage,
    bool? lastMessageIsMine,
    DateTime? lastMessageAt,
  }) =>
      ConversationModel(
        threadKey: threadKey,
        bookingId: bookingId,
        bookingNumber: bookingNumber,
        bookingStatus: bookingStatus,
        serviceTitle: serviceTitle,
        participantId: participantId,
        participantName: participantName,
        participantAvatar: participantAvatar,
        providerProfileId: providerProfileId,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageIsMine: lastMessageIsMine ?? this.lastMessageIsMine,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
      );
}
