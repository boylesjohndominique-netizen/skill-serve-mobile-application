/// Mirrors the `messages` table.
class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
        id: json['message_id'].toString(),
        senderId: json['sender_id'].toString(),
        receiverId: json['receiver_id'].toString(),
        content: json['content'] as String? ?? '',
        sentAt: DateTime.tryParse(json['sent_at'] as String? ?? '') ?? DateTime.now(),
        isRead: json['is_read'] as bool? ?? false,
      );
}

/// UI-level grouping of messages with one counterpart — not a DB table,
/// but a convenience shape for the chat list screen.
class ConversationModel {
  final String id;
  final String participantName;
  final String? participantAvatar;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isOnline;

  const ConversationModel({
    required this.id,
    required this.participantName,
    this.participantAvatar,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
  });
}
