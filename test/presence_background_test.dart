import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skilllink_mobile/core/services/background_notifications.dart';
import 'package:skilllink_mobile/core/services/realtime_client.dart';
import 'package:skilllink_mobile/core/services/token_storage.dart';

/// Answers every request with [body] and records what was asked.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);

  final Map<String, dynamic> body;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _notification(String id, String createdAt) => {
      'id': id,
      'type': 'booking_status',
      'title': 'Booking accepted',
      'message': 'Your provider accepted.',
      'data': {'booking_id': 42},
      'created_at': createdAt,
    };

void main() {
  group('RealtimeClient presence', () {
    final client = RealtimeClient.instance;
    tearDown(client.disconnect);

    test('tracks who is in the channel and routes client events', () {
      final members = <Set<String>>[];
      final events = <String>[];
      client.joinPresence(
        'booking-chat.42',
        onMembers: members.add,
        onClientEvent: (event, data) => events.add('$event:${data['user_id']}'),
      );

      client.handleMessageForTesting(jsonEncode({
        'event': 'pusher_internal:subscription_succeeded',
        'channel': 'presence-booking-chat.42',
        'data': jsonEncode({'presence': {'ids': [7], 'hash': {}, 'count': 1}}),
      }));
      client.handleMessageForTesting(jsonEncode({
        'event': 'pusher_internal:member_added',
        'channel': 'presence-booking-chat.42',
        'data': jsonEncode({'user_id': 9, 'user_info': {'name': 'Juan'}}),
      }));
      client.handleMessageForTesting(jsonEncode({
        'event': 'client-typing',
        'channel': 'presence-booking-chat.42',
        'data': {'user_id': '9', 'typing': true},
      }));
      client.handleMessageForTesting(jsonEncode({
        'event': 'pusher_internal:member_removed',
        'channel': 'presence-booking-chat.42',
        'data': jsonEncode({'user_id': 9}),
      }));

      expect(members, [
        {'7'},
        {'7', '9'},
        {'7'},
      ]);
      expect(events, ['typing:9']);
    });

    test('a channel that was left no longer reports anything', () {
      final members = <Set<String>>[];
      client.joinPresence('booking-chat.5', onMembers: members.add);
      client.leavePresence('booking-chat.5');

      client.handleMessageForTesting(jsonEncode({
        'event': 'pusher_internal:member_added',
        'channel': 'presence-booking-chat.5',
        'data': jsonEncode({'user_id': 3}),
      }));

      expect(members, isEmpty);
    });
  });

  group('BackgroundNotifications.check', () {
    test('does nothing without a background token', () async {
      SharedPreferences.setMockInitialValues({});
      final adapter = _FakeAdapter({'data': []});

      expect(await BackgroundNotifications.check(client: Dio()..httpClientAdapter = adapter), isTrue);
      expect(adapter.requests, isEmpty);
    });

    test('asks for what is new with the narrow token, then moves the cursor and remembers ids', () async {
      SharedPreferences.setMockInitialValues({
        'skillserve.background.after': '2026-09-21T01:00:00Z',
        // On screen: the realtime banner already showed these.
        BackgroundNotifications.foregroundKey: true,
      });
      FlutterSecureStorage.setMockInitialValues({TokenStorage.backgroundTokenKey: 'bg-token'});
      final adapter = _FakeAdapter({
        'data': [
          _notification('a', '2026-09-21T02:00:00+00:00'),
          _notification('b', '2026-09-21T03:00:00+00:00'),
        ],
      });

      await BackgroundNotifications.check(client: Dio()..httpClientAdapter = adapter);

      final request = adapter.requests.single;
      expect(request.path, '/client/v1/notifications/background');
      expect(request.queryParameters['after'], '2026-09-21T01:00:00Z');
      expect(request.headers['Authorization'], 'Bearer bg-token');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('skillserve.background.after'), '2026-09-21T03:00:00+00:00');
      expect(prefs.getStringList('skillserve.background.seenIds'), ['a', 'b']);
    });

    test('a notification already handled is not counted again', () async {
      SharedPreferences.setMockInitialValues({
        'skillserve.background.seenIds': ['a'],
        BackgroundNotifications.foregroundKey: true,
      });
      FlutterSecureStorage.setMockInitialValues({TokenStorage.backgroundTokenKey: 'bg-token'});
      final adapter = _FakeAdapter({
        'data': [_notification('a', '2026-09-21T02:00:00+00:00')],
      });

      await BackgroundNotifications.check(client: Dio()..httpClientAdapter = adapter);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('skillserve.background.seenIds'), ['a']);
    });
  });
}
