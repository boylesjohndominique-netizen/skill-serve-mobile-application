import 'package:flutter_test/flutter_test.dart';
import 'package:skilllink_mobile/features/messaging/controllers/chat_controller.dart';
import 'package:skilllink_mobile/features/messaging/models/message_model.dart';

ConversationModel _conversation(String bookingId, {int unread = 0, String last = 'Earlier.'}) =>
    ConversationModel(
      bookingId: bookingId,
      participantName: 'Provider $bookingId',
      lastMessage: last,
      lastMessageIsMine: true,
      lastMessageAt: DateTime(2026, 9, 20),
      unreadCount: unread,
    );

Map<String, dynamic> _push(String id, String content) => {
      'id': id,
      'booking_id': 2,
      'content': content,
      'sender': {'id': 9, 'name': 'Juan'},
      'receiver': {'id': 7, 'name': 'Maria'},
      'read_at': null,
      'created_at': '2026-09-21T10:00:00+08:00',
    };

void main() {
  test('a message for a closed thread updates the inbox from the push alone', () async {
    final chat = ChatController()
      ..conversations = [_conversation('1'), _conversation('2', unread: 1)]
      ..unreadCount = 1;

    await chat.onRealtimeMessage('2', _push('50', 'On my way.'));

    // Moved to the top, previewed, and counted — without a network round trip.
    expect(chat.conversations.first.bookingId, '2');
    expect(chat.conversations.first.lastMessage, 'On my way.');
    expect(chat.conversations.first.lastMessageIsMine, isFalse);
    expect(chat.conversations.first.unreadCount, 2);
    expect(chat.unreadCount, 2);
    expect(chat.conversations, hasLength(2));
  });

  test('a message for the open thread appears at once and adds no unread', () async {
    final chat = ChatController()
      ..conversations = [_conversation('1'), _conversation('2')]
      ..activeBookingId = '2'
      ..unreadCount = 0;

    await chat.onRealtimeMessage('2', _push('51', 'Almost there.'));

    expect(chat.activeMessages.map((m) => m.content), ['Almost there.']);
    expect(chat.conversations.first.bookingId, '2');
    expect(chat.conversations.first.unreadCount, 0);
    // The server may not be reachable in a test; the badge must not go up.
    expect(chat.unreadCount, 0);
  });

  test('the same push twice does not duplicate the bubble', () async {
    final chat = ChatController()
      ..conversations = [_conversation('2')]
      ..activeBookingId = '2';

    await chat.onRealtimeMessage('2', _push('52', 'Hello.'));
    await chat.onRealtimeMessage('2', _push('52', 'Hello.'));

    expect(chat.activeMessages, hasLength(1));
  });
}
