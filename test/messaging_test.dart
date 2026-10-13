import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/features/messaging/models/message_model.dart';

/// A `BookingMessage` payload as the API returns it.
Map<String, dynamic> messagePayload([Map<String, dynamic> overrides = const {}]) => {
      'id': 17,
      'booking_id': 42,
      'content': 'On my way.',
      'sender': {'id': 5, 'name': 'Maria Santos'},
      'receiver': {'id': 9, 'name': 'Juan Aircon Services'},
      'read_at': null,
      'created_at': '2026-09-30T14:05:00+08:00',
      ...overrides,
    };

/// A `Conversation` payload as the inbox returns it.
Map<String, dynamic> conversationPayload([Map<String, dynamic> overrides = const {}]) => {
      'booking_id': 42,
      'booking_number': 'BK-ABC123',
      'booking_status': 'confirmed',
      'service_title': 'Aircon Cleaning',
      'counterpart': {
        'id': 9,
        'name': 'Juan Aircon Services',
        'profile_picture': 'https://example.test/avatar.png',
      },
      'last_message': {
        'id': 17,
        'content': 'On my way.',
        'created_at': '2026-09-30T14:05:00+08:00',
        'read_at': null,
        'is_mine': false,
      },
      'unread_count': 2,
      'last_message_at': '2026-09-30T14:05:00+08:00',
      ...overrides,
    };

void main() {
  group('MessageModel', () {
    test('a photo message carries its private image url and previews as a photo', () {
      final photo = MessageModel.fromJson(messagePayload({
        'content': null,
        'image_url': 'https://api.test/api/client/v1/bookings/42/messages/17/image',
      }));

      expect(photo.hasImage, isTrue);
      expect(photo.imageUrl, endsWith('/messages/17/image'));
      expect(photo.content, '');
      expect(photo.preview, '📷 Photo');

      final captioned = MessageModel.fromJson(messagePayload({'image_url': 'https://api.test/x'}));
      expect(captioned.preview, 'On my way.');

      final text = MessageModel.fromJson(messagePayload());
      expect(text.hasImage, isFalse);
      expect(text.imageUrl, isNull);
    });

    test('a photo being sent keeps its local file through a failed send', () {
      final pending = MessageModel(
        id: 'pending-1',
        senderId: '5',
        content: '',
        sentAt: DateTime(2026, 10, 13),
        localImagePath: '/tmp/photo.jpg',
        isPending: true,
      );

      final failed = pending.copyWith(isPending: false, hasFailed: true);
      expect(failed.localImagePath, '/tmp/photo.jpg');
      expect(failed.hasImage, isTrue);
      expect(failed.preview, '📷 Photo');
    });

    test('parses a booking message payload', () {
      final message = MessageModel.fromJson(messagePayload());

      expect(message.id, '17');
      expect(message.senderId, '5');
      expect(message.senderName, 'Maria Santos');
      expect(message.receiverId, '9');
      expect(message.content, 'On my way.');
      expect(message.isRead, isFalse);
      expect(message.isPending, isFalse);
      expect(message.hasFailed, isFalse);
    });

    test('a read receipt is the presence of read_at', () {
      final read = MessageModel.fromJson(
          messagePayload({'read_at': '2026-09-30T14:06:00+08:00'}));

      expect(read.isRead, isTrue);
      expect(read.readAt, isNotNull);
    });

    test('a payload without sender or receiver blocks still parses', () {
      final message = MessageModel.fromJson({
        'id': 3,
        'content': 'Minimal.',
        'created_at': '2026-09-30T14:05:00+08:00',
      });

      expect(message.senderId, '');
      expect(message.receiverId, '');
      expect(message.content, 'Minimal.');
    });

    test('copyWith flips only the delivery flags', () {
      final message = MessageModel.fromJson(messagePayload());
      final failed = message.copyWith(isPending: false, hasFailed: true);

      expect(failed.hasFailed, isTrue);
      expect(failed.isPending, isFalse);
      expect(failed.id, message.id);
      expect(failed.content, message.content);
      expect(failed.senderId, message.senderId);
    });
  });

  group('ConversationModel', () {
    test('parses a conversation payload', () {
      final conversation = ConversationModel.fromJson(conversationPayload());

      // The booking addresses the thread.
      expect(conversation.bookingId, '42');
      expect(conversation.bookingNumber, 'BK-ABC123');
      expect(conversation.bookingStatus, 'confirmed');
      expect(conversation.serviceTitle, 'Aircon Cleaning');
      expect(conversation.participantId, '9');
      expect(conversation.participantName, 'Juan Aircon Services');
      expect(conversation.participantAvatar, 'https://example.test/avatar.png');
      expect(conversation.lastMessage, 'On my way.');
      expect(conversation.lastMessageIsMine, isFalse);
      expect(conversation.unreadCount, 2);
      expect(conversation.lastMessageAt, isNotNull);
    });

    test('a customer\'s thread carries the provider\'s public profile id', () {
      final withProvider = ConversationModel.fromJson(conversationPayload({
        'counterpart': {'id': 9, 'provider_id': 3, 'name': 'Juan Aircon Services', 'profile_picture': null},
      }));
      expect(withProvider.providerProfileId, '3');
      // Updating the unread count keeps the link to the profile.
      expect(withProvider.copyWith(unreadCount: 0).providerProfileId, '3');

      // The provider's side of the thread names a customer: no profile id.
      expect(ConversationModel.fromJson(conversationPayload()).providerProfileId, isNull);
    });

    test('the preview marks your own last message', () {
      expect(ConversationModel.fromJson(conversationPayload()).preview, 'On my way.');

      final mine = ConversationModel.fromJson(conversationPayload({
        'last_message': {'id': 17, 'content': 'See you then.', 'is_mine': true},
      }));
      expect(mine.preview, 'You: See you then.');
    });

    test('a thread with no messages previews as empty rather than blank', () {
      final empty = ConversationModel.fromJson(conversationPayload({'last_message': null}));

      expect(empty.lastMessage, '');
      expect(empty.preview, 'No messages yet');
    });

    test('search matches the counterpart, service, booking number and message', () {
      final conversation = ConversationModel.fromJson(conversationPayload());

      // An empty query matches everything, so the list is not hidden.
      expect(conversation.matches(''), isTrue);
      expect(conversation.matches('  '), isTrue);

      expect(conversation.matches('juan'), isTrue);
      expect(conversation.matches('AIRCON'), isTrue);
      expect(conversation.matches('bk-abc'), isTrue);
      expect(conversation.matches('on my way'), isTrue);
      expect(conversation.matches('plumbing'), isFalse);
    });

    test('copyWith clears an unread count without touching the rest', () {
      final read = ConversationModel.fromJson(conversationPayload()).copyWith(unreadCount: 0);

      expect(read.unreadCount, 0);
      expect(read.bookingId, '42');
      expect(read.participantName, 'Juan Aircon Services');
      expect(read.lastMessage, 'On my way.');
    });
  });
}
