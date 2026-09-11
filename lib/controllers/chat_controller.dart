import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class ChatController extends ChangeNotifier {
  final MessageService _service = MessageService();

  List<ConversationModel> conversations = [];
  List<MessageModel> activeMessages = [];
  bool isLoading = false;

  Future<void> loadConversations() async {
    isLoading = true;
    notifyListeners();
    try {
      conversations = await _service.getConversations();
    } catch (_) {
      conversations = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> openConversation(String conversationId) async {
    isLoading = true;
    notifyListeners();
    try {
      activeMessages = await _service.getMessages(conversationId);
    } catch (_) {
      activeMessages = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> send(String conversationId, String content) async {
    if (content.trim().isEmpty) return;
    activeMessages = [
      ...activeMessages,
      MessageModel(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        senderId: 'me',
        receiverId: 'other',
        content: content,
        sentAt: DateTime.now(),
        isRead: false,
      ),
    ];
    notifyListeners();
    try {
      await _service.sendMessage(conversationId, content);
    } catch (_) {}
  }
}
