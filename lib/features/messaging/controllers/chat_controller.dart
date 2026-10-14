import 'package:flutter/foundation.dart';
import '../../../core/utils/api_error.dart';
import '../models/chat_thread.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

/// State for the Messages tab and the open conversation.
///
/// Every thread — a booking's chat or a conversation before booking — is
/// keyed by its [ChatThread] key.
class ChatController extends ChangeNotifier {
  final MessageService _service = MessageService();

  List<ConversationModel> conversations = [];
  bool isLoading = false;
  String? errorMessage;

  /// Unread messages across every thread, for the Messages tab badge.
  int unreadCount = 0;

  /// The thread currently on screen, or null when none is open.
  String? activeThreadKey;
  List<MessageModel> activeMessages = [];
  bool isThreadLoading = false;
  String? threadErrorMessage;
  bool isSending = false;

  /// Conversations matching the inbox search box.
  /// A conversation before booking that nobody has written in yet stays out
  /// of the list (the server leaves it out too).
  List<ConversationModel> search(String query) => conversations
      .where((c) => !(c.isInquiry && c.lastMessageAt == null))
      .where((c) => c.matches(query))
      .toList();

  /// The conversation for [threadKey] if the inbox has been loaded, so the
  /// thread screen can title itself before its messages arrive.
  ConversationModel? conversationFor(String threadKey) {
    for (final conversation in conversations) {
      if (conversation.threadKey == threadKey) return conversation;
    }
    return null;
  }

  /// Opens (starting it the first time) the customer's conversation with
  /// [providerId] before booking, and makes sure the inbox knows it so the
  /// chat header has the provider. Returns null and sets [errorMessage] when
  /// the API refuses.
  Future<ConversationModel?> startInquiry(String providerId) async {
    errorMessage = null;
    try {
      final conversation = await _service.startInquiry(providerId);
      if (conversationFor(conversation.threadKey) == null) {
        conversations = [...conversations, conversation];
        notifyListeners();
      }
      return conversation;
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to start this conversation.');
      notifyListeners();
      return null;
    }
  }

  Future<void> loadConversations() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      conversations = await _service.getConversations();
      unreadCount = conversations.fold(0, (sum, c) => sum + c.unreadCount);
    } catch (e) {
      conversations = [];
      errorMessage = apiErrorMessage(e, 'Unable to load your messages.');
    }
    isLoading = false;
    notifyListeners();
  }

  /// Refreshes just the badge. Silent: a failure here must not put an error on
  /// a screen the user is not looking at.
  Future<void> refreshUnreadCount() async {
    try {
      final count = await _service.getUnreadCount();
      if (count == unreadCount) return;
      unreadCount = count;
      notifyListeners();
    } catch (_) {
      // Leave the last known count in place.
    }
  }

  /// Opens a thread. Reading it marks its messages read server-side, so the
  /// inbox row and the badge are brought in line locally.
  Future<void> openConversation(String threadKey) async {
    activeThreadKey = threadKey;
    isThreadLoading = true;
    threadErrorMessage = null;
    activeMessages = [];
    notifyListeners();
    try {
      activeMessages = await _service.getMessages(threadKey);
      _clearUnread(threadKey);
    } catch (e) {
      activeMessages = [];
      threadErrorMessage = apiErrorMessage(e, 'Unable to load this conversation.');
    }
    isThreadLoading = false;
    notifyListeners();
  }

  void closeConversation() {
    activeThreadKey = null;
    activeMessages = [];
    threadErrorMessage = null;
    notifyListeners();
  }

  /// Sends a message — text, a photo ([imagePath]) or both — showing it
  /// immediately and reconciling with the API.
  ///
  /// The optimistic bubble carries a temporary id and is replaced by the stored
  /// message on success, or flagged as failed so the user can retry — it is
  /// never silently dropped or left looking sent.
  Future<bool> send(String threadKey, String content, {required String myUserId, String? imagePath}) async {
    final text = content.trim();
    if (text.isEmpty && imagePath == null) return false;

    final temporaryId = 'pending-${DateTime.now().microsecondsSinceEpoch}';
    final pending = MessageModel(
      id: temporaryId,
      senderId: myUserId,
      content: text,
      sentAt: DateTime.now(),
      localImagePath: imagePath,
      isPending: true,
    );

    activeMessages = [...activeMessages, pending];
    isSending = true;
    notifyListeners();

    try {
      final sent = await _service.sendMessage(
        threadKey,
        text,
        imagePath: imagePath,
        // The temporary id doubles as the idempotency key, so a retry after a
        // timeout cannot post the same message twice.
        idempotencyKey: temporaryId,
      );
      _replaceMessage(temporaryId, sent);
      _bumpConversation(threadKey, sent, countAsUnread: false, mine: true);
      return true;
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to send this message.');
      _replaceMessage(temporaryId, pending.copyWith(isPending: false, hasFailed: true));
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  /// Retries a failed message: drops the failed bubble and sends it again.
  Future<bool> retry(String threadKey, MessageModel failed, {required String myUserId}) async {
    activeMessages = activeMessages.where((m) => m.id != failed.id).toList();
    notifyListeners();
    return send(threadKey, failed.content, myUserId: myUserId, imagePath: failed.localImagePath);
  }

  /// A message pushed over the realtime channel.
  ///
  /// The push carries the whole message, so the inbox row is updated from it
  /// directly rather than refetching the inbox. When its thread is open the
  /// bubble appears at once and one small request marks it read, so a message
  /// the user is looking at never leaves an unread badge behind. Only a message
  /// in a conversation the inbox has not seen yet costs a reload.
  Future<void> onRealtimeMessage(String threadKey, Map<String, dynamic> payload) async {
    final message = MessageModel.fromJson(payload);
    final isOpen = activeThreadKey == threadKey;

    if (isOpen && !activeMessages.any((m) => m.id == message.id)) {
      activeMessages = [...activeMessages, message];
    }

    final known = _bumpConversation(threadKey, message, countAsUnread: !isOpen);
    if (!isOpen) unreadCount += 1;
    notifyListeners();

    if (!known) {
      await _refreshConversationsQuietly();
      return;
    }

    if (isOpen) {
      try {
        unreadCount = await _service.markThreadRead(threadKey);
        notifyListeners();
      } catch (_) {
        // Stays unread on the server; the next open of the thread clears it.
      }
    }
  }

  /// Moves a conversation to the top of the inbox with [message] as its
  /// preview. Returns false when the inbox does not have that conversation.
  bool _bumpConversation(String threadKey, MessageModel message, {required bool countAsUnread, bool mine = false}) {
    final index = conversations.indexWhere((c) => c.threadKey == threadKey);
    if (index == -1) return false;

    final current = conversations[index];
    final updated = current.copyWith(
      lastMessage: message.preview,
      lastMessageIsMine: mine,
      lastMessageAt: message.sentAt,
      unreadCount: countAsUnread ? current.unreadCount + 1 : 0,
    );
    conversations = [updated, ...conversations.where((c) => c.threadKey != threadKey)];
    return true;
  }

  /// Reloads the inbox without flipping [isLoading], so a message arriving
  /// never replaces the list the user is reading with a shimmer.
  Future<void> _refreshConversationsQuietly() async {
    try {
      conversations = await _service.getConversations();
      unreadCount = conversations.fold(0, (sum, c) => sum + c.unreadCount);
      notifyListeners();
    } catch (_) {
      // Keep the list that is already on screen.
    }
  }

  /// Zeroes the unread count for a thread that was just opened.
  void _clearUnread(String threadKey) {
    final index = conversations.indexWhere((c) => c.threadKey == threadKey);
    if (index == -1) return;

    final cleared = conversations[index].unreadCount;
    if (cleared == 0) return;

    conversations = [...conversations]..[index] = conversations[index].copyWith(unreadCount: 0);
    unreadCount = (unreadCount - cleared).clamp(0, unreadCount);
  }

  void _replaceMessage(String id, MessageModel replacement) {
    final index = activeMessages.indexWhere((m) => m.id == id);
    if (index == -1) return;
    activeMessages = [...activeMessages]..[index] = replacement;
  }
}
