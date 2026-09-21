import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import 'api_client.dart';

/// Minimal Laravel Reverb (Pusher protocol v7) client for private and
/// presence channels.
///
/// Connects, authorizes channels through `/api/broadcasting/auth` with the
/// signed-in user's bearer token, answers server pings, and reconnects with
/// back-off. [isConnected] reports whether events can currently arrive, so
/// callers can fall back to polling.
///
/// Presence channels ([joinPresence]) report who else is subscribed and carry
/// client events ([whisper]) between members — used for "in this chat" and
/// "typing…" in a conversation.
class RealtimeClient {
  RealtimeClient._();

  static final RealtimeClient instance = RealtimeClient._();

  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  final Map<String, Map<String, void Function(Map<String, dynamic> data)>> _handlers = {};
  final Map<String, _Presence> _presence = {};
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  String? _socketId;
  bool _wanted = false;
  int _attempt = 0;

  /// Subscribe to [event] on private channel [channel] (without `private-`).
  void listen(String channel, String event, void Function(Map<String, dynamic> data) handler) {
    final name = 'private-$channel';
    final isNew = !_handlers.containsKey(name);
    _handlers.putIfAbsent(name, () => {})[event] = handler;
    _wanted = true;

    if (_channel == null) {
      _connect();
    } else if (isNew && _socketId != null) {
      _subscribe(name);
    }
  }

  /// Join presence channel [channel] (without `presence-`). [onMembers] gets
  /// the ids of everyone subscribed — including this user — whenever that
  /// changes; [onClientEvent] gets `client-…` events other members send.
  void joinPresence(
    String channel, {
    required void Function(Set<String> memberIds) onMembers,
    void Function(String event, Map<String, dynamic> data)? onClientEvent,
  }) {
    final name = 'presence-$channel';
    _presence[name] = _Presence(onMembers, onClientEvent);
    _wanted = true;

    if (_channel == null) {
      _connect();
    } else if (_socketId != null) {
      _subscribe(name);
    }
  }

  /// Leave presence channel [channel] (without `presence-`).
  void leavePresence(String channel) {
    final name = 'presence-$channel';
    if (_presence.remove(name) != null) {
      _send({'event': 'pusher:unsubscribe', 'data': {'channel': name}});
    }
  }

  /// Send client event [event] (without `client-`) to the other members of
  /// presence channel [channel]. Dropped silently while disconnected: these
  /// are ephemeral hints, never data.
  void whisper(String channel, String event, Map<String, dynamic> data) {
    final name = 'presence-$channel';
    if (_socketId == null || !_presence.containsKey(name)) return;
    _send({'event': 'client-$event', 'channel': name, 'data': data});
  }

  /// Leave every channel and close the connection (e.g. on logout).
  void disconnect() {
    _wanted = false;
    _handlers.clear();
    _presence.clear();
    _close();
  }

  void _connect() {
    if (!_wanted) return;
    _close();
    try {
      final channel = WebSocketChannel.connect(AppConfig.reverbUri);
      _channel = channel;
      _subscription = channel.stream.listen(
        _onMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  @visibleForTesting
  void handleMessageForTesting(dynamic raw) => _onMessage(raw);

  void _onMessage(dynamic raw) {
    final message = _decode(raw);
    if (message == null) return;
    final event = message['event'] as String?;
    final data = message['data'] is String ? _decode(message['data']) : message['data'];

    switch (event) {
      case 'pusher:connection_established':
        _attempt = 0;
        final established = data is Map ? data : const {};
        _socketId = established['socket_id'] as String?;
        final timeout = (established['activity_timeout'] as num?)?.toInt() ?? 30;
        _pingTimer?.cancel();
        _pingTimer = Timer.periodic(Duration(seconds: timeout), (_) => _send({'event': 'pusher:ping', 'data': {}}));
        for (final name in [..._handlers.keys, ..._presence.keys]) {
          _subscribe(name);
        }
      case 'pusher:ping':
        _send({'event': 'pusher:pong', 'data': {}});
      case 'pusher_internal:subscription_succeeded':
        isConnected.value = true;
        final presence = _presence[message['channel']];
        if (presence != null && data is Map) {
          final ids = (data['presence'] is Map ? data['presence']['ids'] : null) as List? ?? const [];
          presence.members
            ..clear()
            ..addAll(ids.map((id) => id.toString()));
          presence.onMembers(Set.of(presence.members));
        }
      case 'pusher_internal:member_added' || 'pusher_internal:member_removed':
        final presence = _presence[message['channel']];
        final userId = data is Map ? data['user_id']?.toString() : null;
        if (presence != null && userId != null) {
          event == 'pusher_internal:member_added'
              ? presence.members.add(userId)
              : presence.members.remove(userId);
          presence.onMembers(Set.of(presence.members));
        }
      case 'pusher:subscription_error':
        debugPrint('[Realtime] subscription refused for ${message['channel']}');
      case 'pusher:error':
        debugPrint('[Realtime] server error: $data');
      default:
        if (event != null && event.startsWith('client-')) {
          final onClientEvent = _presence[message['channel']]?.onClientEvent;
          if (onClientEvent != null && data is Map<String, dynamic>) {
            onClientEvent(event.substring('client-'.length), data);
          }
          return;
        }
        final handler = _handlers[message['channel']]?[event];
        if (handler != null && data is Map<String, dynamic>) handler(data);
    }
  }

  Future<void> _subscribe(String name) async {
    final socketId = _socketId;
    if (socketId == null) return;
    try {
      final response = await ApiClient.instance.dio.post(
        AppConfig.broadcastingAuthUrl,
        data: {'socket_id': socketId, 'channel_name': name},
      );
      final body = response.data as Map;
      final auth = body['auth'] as String?;
      if (auth == null || socketId != _socketId) return;
      _send({
        'event': 'pusher:subscribe',
        'data': {
          'channel': name,
          'auth': auth,
          // Presence channels also carry the member info the auth signed.
          if (body['channel_data'] != null) 'channel_data': body['channel_data'],
        },
      });
    } catch (e) {
      debugPrint('[Realtime] channel auth failed for $name: $e');
    }
  }

  void _send(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (_) {}
  }

  void _scheduleReconnect() {
    _close();
    if (!_wanted) return;
    // 1s, 2s, 4s … capped at 30s.
    final delay = Duration(seconds: (1 << _attempt.clamp(0, 5)).clamp(1, 30));
    _attempt++;
    _reconnectTimer = Timer(delay, _connect);
  }

  void _close() {
    isConnected.value = false;
    _socketId = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  static Map<String, dynamic>? _decode(dynamic raw) {
    try {
      final value = raw is String ? jsonDecode(raw) : raw;
      return value is Map<String, dynamic> ? value : null;
    } catch (_) {
      return null;
    }
  }
}

class _Presence {
  _Presence(this.onMembers, this.onClientEvent);

  final void Function(Set<String> memberIds) onMembers;
  final void Function(String event, Map<String, dynamic> data)? onClientEvent;
  final Set<String> members = {};
}
