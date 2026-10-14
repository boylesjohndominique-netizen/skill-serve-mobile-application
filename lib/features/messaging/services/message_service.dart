import 'package:dio/dio.dart';

import '../models/chat_thread.dart';
import '../models/message_model.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/image_upload.dart';

/// Service for conversations and messages — live API only.
///
/// A thread is a booking's chat, or a conversation with a provider before
/// booking; both are addressed by a [ChatThread] key and share one API shape.
///
/// Endpoints (api-docs/modules/conversations.md, booking-messages.md, inquiries.md):
/// - GET  /api/client/v1/conversations?include_inquiries=1
/// - GET  /api/client/v1/conversations/unread-count
/// - POST /api/client/v1/inquiries (start or reopen a conversation before booking)
/// - GET|POST /api/client/v1/{bookings|inquiries}/{id}/messages
/// - POST /api/client/v1/{bookings|inquiries}/{id}/messages/read
class MessageService {
  static const _conversations = '/client/v1/conversations';

  /// GET /api/client/v1/conversations — the Messages inbox. Reading it does
  /// not mark anything read.
  Future<List<ConversationModel>> getConversations() async {
    final response = await ApiClient.instance.dio
        .get(_conversations, queryParameters: {'per_page': 100, 'include_inquiries': 1});
    return [
      for (final item in response.data['data'] as List? ?? const [])
        ConversationModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// GET /api/client/v1/conversations/unread-count — for the Messages badge.
  Future<int> getUnreadCount() async {
    final response = await ApiClient.instance.dio.get('$_conversations/unread-count');
    final data = response.data['data'] as Map<String, dynamic>?;
    return (data?['unread_count'] as num?)?.toInt() ?? 0;
  }

  /// POST /api/client/v1/inquiries — the customer's conversation with
  /// [providerId] before booking, started the first time.
  Future<ConversationModel> startInquiry(String providerId) async {
    final response = await ApiClient.instance.dio
        .post('/client/v1/inquiries', data: {'provider_id': int.tryParse(providerId) ?? providerId});
    return ConversationModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// GET …/messages — the thread, oldest first. Opening it marks the
  /// messages addressed to the caller as read.
  Future<List<MessageModel>> getMessages(String threadKey) async {
    final response = await ApiClient.instance.dio.get(ChatThread.messagesPath(threadKey));
    return [
      for (final item in response.data['data'] as List? ?? const [])
        MessageModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// POST …/messages — text, a photo
  /// ([imagePath], sent as multipart), or both. [idempotencyKey] makes a
  /// retried send return the message already stored instead of a duplicate.
  Future<MessageModel> sendMessage(
    String threadKey,
    String content, {
    String? imagePath,
    String? idempotencyKey,
  }) async {
    final response = await ApiClient.instance.dio.post(
      ChatThread.messagesPath(threadKey),
      data: imagePath == null
          ? {'content': content}
          : FormData.fromMap({
              if (content.isNotEmpty) 'content': content,
              'image': await imageMultipart(imagePath),
            }),
      options: idempotencyKey == null ? null : Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return MessageModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// POST …/messages/read — clears the
  /// thread's unread state without re-reading it. Returns the unread total
  /// left across every thread, for the Messages badge.
  Future<int> markThreadRead(String threadKey) async {
    final response = await ApiClient.instance.dio.post('${ChatThread.messagesPath(threadKey)}/read');
    final data = response.data['data'] as Map<String, dynamic>?;
    return (data?['unread_count'] as num?)?.toInt() ?? 0;
  }
}
