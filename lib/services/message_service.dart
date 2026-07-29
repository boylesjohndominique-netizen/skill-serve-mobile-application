import '../data/mock/mock_data.dart';
import '../models/message_model.dart';
import 'api_client.dart';

/// Placeholder service for chat conversations and messages.
class MessageService {
  // GET /conversations
  Future<List<ConversationModel>> getConversations() async {
    await simulateNetworkDelay(ms: 350);
    return MockData.conversations;
  }

  // GET /conversations/:id/messages
  Future<List<MessageModel>> getMessages(String conversationId) async {
    await simulateNetworkDelay(ms: 300);
    return MockData.messagesFor(conversationId);
  }

  // POST /conversations/:id/messages
  Future<void> sendMessage(String conversationId, String content) async {
    await simulateNetworkDelay(ms: 250);
  }
}
