import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import 'api_client.dart';

/// Minimal Laravel Reverb (Pusher protocol v7) client for private channels.
///
/// Connects, authorizes channels through `/api/broadcasting/auth` with the
/// signed-in user's bearer token, answers server pings, and reconnects with
/// back-off. [isConnected] reports whether events can currently arrive, so
/// callers can fall back to polling.
class RealtimeClient {
  RealtimeClient._();

  static final RealtimeClient instance = RealtimeClient._();

  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  final Map<String, Map<String, void Function(Map<String, dynamic> data)>> _handlers = {};
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

  /// Leave every channel and close the connection (e.g. on logout).
  void disconnect() {
    _wanted = false;
    _handlers.clear();
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
        for (final name in _handlers.keys) {
          _subscribe(name);
        }
      case 'pusher:ping':
        _send({'event': 'pusher:pong', 'data': {}});
      case 'pusher_internal:subscription_succeeded':
        isConnected.value = true;
      case 'pusher:subscription_error':
        debugPrint('[Realtime] subscription refused for ${message['channel']}');
      case 'pusher:error':
        debugPrint('[Realtime] server error: $data');
      default:
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
      final auth = (response.data as Map)['auth'] as String?;
      if (auth == null || socketId != _socketId) return;
      _send({'event': 'pusher:subscribe', 'data': {'channel': name, 'auth': auth}});
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
