import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({NotificationService? service}) : _service = service ?? NotificationService();

  /// Fallback check interval while the realtime (WebSocket) connection is
  /// down. When it is up, new notifications arrive instantly instead.
  static const pollInterval = Duration(seconds: 30);

  final NotificationService _service;

  List<NotificationModel> notifications = [];
  bool isLoading = false;
  int unreadCount = 0;

  /// The newest notification that arrived since the last check; the app shell
  /// shows it as a banner and then calls [clearIncoming].
  NotificationModel? incoming;

  Timer? _timer;
  bool _checking = false;
  bool _pushPending = false;
  bool _hasBaseline = false;

  bool get isPolling => _timer != null;

  /// Set by the app shell while the realtime connection is live; periodic
  /// checks are skipped then.
  bool realtimeConnected = false;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    try {
      notifications = await _service.getNotifications();
      unreadCount = notifications.where((n) => !n.isRead).length;
    } catch (_) {
      notifications = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    await _service.markAsRead(id);
    notifications = [
      for (final n in notifications)
        if (n.id == id)
          NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            createdAt: n.createdAt,
            isRead: true,
          )
        else
          n,
    ];
    unreadCount = notifications.where((n) => !n.isRead).length;
    notifyListeners();
  }

  /// Starts checking for new notifications (idempotent).
  void startPolling() {
    if (_timer != null) return;
    _timer = Timer.periodic(pollInterval, (_) {
      if (!realtimeConnected) checkForNew();
    });
    checkForNew();
  }

  /// Pauses checking, e.g. while the app is in the background.
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  /// Stops checking and forgets the signed-in user's notifications.
  void reset() {
    stopPolling();
    notifications = [];
    unreadCount = 0;
    incoming = null;
    _hasBaseline = false;
    notifyListeners();
  }

  /// Fetches the unread count; when it grew (or a notification was pushed
  /// over the realtime connection), reloads the feed and surfaces the newest
  /// unread notification. The first poll only sets the baseline so existing
  /// notifications do not pop up as new.
  Future<void> checkForNew({bool pushed = false}) async {
    if (_checking) {
      _pushPending = _pushPending || pushed;
      return;
    }
    _checking = true;
    try {
      final count = await _service.unreadCount();
      final grew = pushed || (_hasBaseline && count > unreadCount);
      _hasBaseline = true;

      if (grew) {
        notifications = await _service.getNotifications();
        incoming = notifications.where((n) => !n.isRead).firstOrNull;
      }
      if (grew || count != unreadCount) {
        unreadCount = count;
        notifyListeners();
      }
    } catch (_) {
      // Offline or signed out — try again on the next event or tick.
    } finally {
      _checking = false;
    }

    if (_pushPending) {
      _pushPending = false;
      await checkForNew(pushed: true);
    }
  }

  /// A notification was pushed over the realtime connection: fetch it now.
  Future<void> onRealtimeNotification() => checkForNew(pushed: true);

  void clearIncoming() {
    incoming = null;
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
