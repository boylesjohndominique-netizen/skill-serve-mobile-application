import 'package:dio/dio.dart';

import '../models/message_model.dart';
import '../../../core/services/api_client.dart';

/// Service for booking conversations and messages — live API only.
///
/// Messaging is booking-scoped: the client and provider on a booking talk to
/// each other about that job, so a conversation is addressed by its booking id.
///
/// Endpoints (api-docs/modules/conversations.md, booking-messages.md):
/// - GET  /api/client/v1/conversations
/// - GET  /api/client/v1/conversations/unread-count
/// - GET  /api/client/v1/bookings/{booking}/messages
/// - POST /api/client/v1/bookings/{booking}/messages
class MessageService {
  static const _conversations = '/client/v1/conversations';

  /// GET /api/client/v1/conversations — the Messages inbox. Reading it does
  /// not mark anything read.
  Future<List<ConversationModel>> getConversations() async {
    final response = await ApiClient.instance.dio
        .get(_conversations, queryParameters: {'per_page': 100});
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

  /// GET /api/client/v1/bookings/{booking}/messages — the thread, oldest
  /// first. Opening it marks the messages addressed to the caller as read.
  Future<List<MessageModel>> getMessages(String bookingId) async {
    final response =
        await ApiClient.instance.dio.get('/client/v1/bookings/$bookingId/messages');
    return [
      for (final item in response.data['data'] as List? ?? const [])
        MessageModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// POST /api/client/v1/bookings/{booking}/messages. [idempotencyKey] makes a
  /// retried send return the message already stored instead of a duplicate.
  Future<MessageModel> sendMessage(
    String bookingId,
    String content, {
    String? idempotencyKey,
  }) async {
    final response = await ApiClient.instance.dio.post(
      '/client/v1/bookings/$bookingId/messages',
      data: {'content': content},
      options: idempotencyKey == null
          ? null
          : Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return MessageModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
