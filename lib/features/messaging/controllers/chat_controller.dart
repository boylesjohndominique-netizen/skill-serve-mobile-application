import 'package:flutter/foundation.dart';
import '../../../core/utils/api_error.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

/// State for the Messages tab and the open conversation.
///
/// A booking is the conversation, so every thread is keyed by its booking id.
class ChatController extends ChangeNotifier {
  final MessageService _service = MessageService();

  List<ConversationModel> conversations = [];
  bool isLoading = false;
  String? errorMessage;

  /// Unread messages across every thread, for the Messages tab badge.
  int unreadCount = 0;

  /// The thread currently on screen, or null when none is open.
  String? activeBookingId;
  List<MessageModel> activeMessages = [];
  bool isThreadLoading = false;
  String? threadErrorMessage;
  bool isSending = false;

  /// Conversations matching the inbox search box.
  List<ConversationModel> search(String query) =>
      conversations.where((c) => c.matches(query)).toList();

  /// The conversation for [bookingId] if the inbox has been loaded, so the
  /// thread screen can title itself before its messages arrive.
  ConversationModel? conversationFor(String bookingId) {
    for (final conversation in conversations) {
      if (conversation.bookingId == bookingId) return conversation;
    }
    return null;
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
  Future<void> openConversation(String bookingId) async {
    activeBookingId = bookingId;
    isThreadLoading = true;
    threadErrorMessage = null;
    activeMessages = [];
    notifyListeners();
    try {
      activeMessages = await _service.getMessages(bookingId);
      _clearUnread(bookingId);
    } catch (e) {
      activeMessages = [];
      threadErrorMessage = apiErrorMessage(e, 'Unable to load this conversation.');
    }
    isThreadLoading = false;
    notifyListeners();
  }

  void closeConversation() {
    activeBookingId = null;
    activeMessages = [];
    threadErrorMessage = null;
    notifyListeners();
  }

  /// Sends a message, showing it immediately and reconciling with the API.
  ///
  /// The optimistic bubble carries a temporary id and is replaced by the stored
  /// message on success, or flagged as failed so the user can retry — it is
  /// never silently dropped or left looking sent.
  Future<bool> send(String bookingId, String content, {required String myUserId}) async {
    final text = content.trim();
    if (text.isEmpty) return false;

    final temporaryId = 'pending-${DateTime.now().microsecondsSinceEpoch}';
    final pending = MessageModel(
      id: temporaryId,
      senderId: myUserId,
      content: text,
      sentAt: DateTime.now(),
      isPending: true,
    );

    activeMessages = [...activeMessages, pending];
    isSending = true;
    notifyListeners();

    try {
      final sent = await _service.sendMessage(
        bookingId,
        text,
        // The temporary id doubles as the idempotency key, so a retry after a
        // timeout cannot post the same message twice.
        idempotencyKey: temporaryId,
      );
      _replaceMessage(temporaryId, sent);
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
  Future<bool> retry(String bookingId, MessageModel failed, {required String myUserId}) async {
    activeMessages = activeMessages.where((m) => m.id != failed.id).toList();
    notifyListeners();
    return send(bookingId, failed.content, myUserId: myUserId);
  }

  /// A message pushed over the realtime channel.
  ///
  /// When its thread is open the bubble appears at once and the thread is then
  /// re-read, which is what marks it read server-side — so a message the user
  /// is looking at never leaves an unread badge behind. Otherwise only the
  /// inbox and the badge move.
  Future<void> onRealtimeMessage(String bookingId, Map<String, dynamic> payload) async {
    if (activeBookingId == bookingId) {
      final message = MessageModel.fromJson(payload);
      // Guard against a duplicate if a refetch raced the push.
      if (!activeMessages.any((m) => m.id == message.id)) {
        activeMessages = [...activeMessages, message];
        notifyListeners();
      }
      await _reconcileThread(bookingId);
      await _refreshConversationsQuietly();
      return;
    }

    unreadCount += 1;
    notifyListeners();
    await _refreshConversationsQuietly();
  }

  /// Re-reads the open thread to pick up server state (read receipts above all)
  /// while keeping bubbles that have not been accepted yet — a refetch must not
  /// swallow a message still in flight or one the user can still retry.
  Future<void> _reconcileThread(String bookingId) async {
    final unsent = activeMessages.where((m) => m.isPending || m.hasFailed).toList();
    try {
      final fetched = await _service.getMessages(bookingId);
      if (activeBookingId != bookingId) return;
      activeMessages = [...fetched, ...unsent];
      _clearUnread(bookingId);
      notifyListeners();
    } catch (_) {
      // The bubble is already on screen; the next open reconciles.
    }
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
  void _clearUnread(String bookingId) {
    final index = conversations.indexWhere((c) => c.bookingId == bookingId);
    if (index == -1) return;

    final cleared = conversations[index].unreadCount;
    if (cleared == 0) return;

    conversations = [...conversations]..[index] =
        conversations[index].copyWith(unreadCount: 0);
    unreadCount = (unreadCount - cleared).clamp(0, unreadCount);
  }

  void _replaceMessage(String id, MessageModel replacement) {
    final index = activeMessages.indexWhere((m) => m.id == id);
    if (index == -1) return;
    activeMessages = [...activeMessages]..[index] = replacement;
  }

}
