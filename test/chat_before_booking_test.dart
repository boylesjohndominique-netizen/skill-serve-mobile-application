import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/features/messaging/controllers/chat_controller.dart';
import 'package:skillserve_mobile/features/messaging/models/chat_thread.dart';
import 'package:skillserve_mobile/features/messaging/models/message_model.dart';

Map<String, dynamic> _inquiry({Map<String, dynamic>? last}) => {
      'kind': 'inquiry',
      'booking_id': null,
      'inquiry_id': 5,
      'booking_number': null,
      'booking_status': null,
      'service_title': null,
      'counterpart': {'id': 9, 'provider_id': 3, 'name': 'Juan Aircon Services'},
      'last_message': last,
      'unread_count': last == null ? 0 : 1,
      'last_message_at': last?['created_at'],
    };

void main() {
  test('threads are addressed by booking id, or inquiry-<id> before booking', () {
    expect(ChatThread.messagesPath('12'), '/client/v1/bookings/12/messages');
    expect(ChatThread.messagesPath('inquiry-5'), '/client/v1/inquiries/5/messages');
    expect(ChatThread.presenceChannel('12'), 'booking-chat.12');
    expect(ChatThread.presenceChannel('inquiry-5'), 'inquiry-chat.5');
    expect(ChatThread.fromIds(bookingId: 12), '12');
    expect(ChatThread.fromIds(bookingId: null, inquiryId: 5), 'inquiry-5');
    expect(ChatThread.fromIds(), isNull);
  });

  test('a conversation before booking reads as one in the inbox', () {
    final conversation = ConversationModel.fromJson(_inquiry(last: {
      'id': 1,
      'content': 'Do you do weekends?',
      'is_mine': true,
      'created_at': '2026-10-14T09:00:00+08:00',
    }));

    expect(conversation.threadKey, 'inquiry-5');
    expect(conversation.isInquiry, isTrue);
    expect(conversation.bookingId, isEmpty);
    expect(conversation.topic, 'Before booking');
    expect(conversation.providerProfileId, '3');
    expect(conversation.preview, 'You: Do you do weekends?');
  });

  test('a just-started conversation stays out of the list until someone writes', () {
    final chat = ChatController()
      ..conversations = [
        ConversationModel.fromJson(_inquiry()),
        ConversationModel(threadKey: '12', bookingId: '12', participantName: 'Maria', lastMessageAt: DateTime(2026, 10, 1)),
      ];

    expect(chat.search('').map((c) => c.threadKey), ['12']);
    // The chat header still finds it.
    expect(chat.conversationFor('inquiry-5')?.participantName, 'Juan Aircon Services');
  });
}
