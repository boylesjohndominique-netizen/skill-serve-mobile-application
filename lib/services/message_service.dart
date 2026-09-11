import '../models/message_model.dart';

/// Service for chat conversations and messages.
///
/// No documented client endpoints for messaging. These methods will
/// throw [UnsupportedError] until the backend documents client chat routes.
class MessageService {
  // No documented client endpoint.
  Future<List<ConversationModel>> getConversations() async {
    throw UnsupportedError(
        'Client messaging endpoints are not documented.');
  }

  // No documented client endpoint.
  Future<List<MessageModel>> getMessages(String conversationId) async {
    throw UnsupportedError(
        'Client messaging endpoints are not documented.');
  }

  // No documented client endpoint.
  Future<void> sendMessage(String conversationId, String content) async {
    throw UnsupportedError(
        'Client messaging endpoints are not documented.');
  }
}
