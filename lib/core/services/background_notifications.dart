import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/notifications/models/notification_model.dart';
import '../config/app_config.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Notifications while the app is closed — without Firebase.
///
/// Android's WorkManager runs [backgroundNotificationDispatcher] about every
/// 15 minutes (the shortest period the OS allows; it may stretch it to save
/// battery). The task asks the Laravel API for unread notifications with a
/// narrow, read-only token and posts each new one as a system notification.
/// It never refreshes the session, so it cannot collide with the app's
/// rotating refresh token. While the app is open, Reverb delivers everything
/// instantly and the task only moves its cursor forward, so nothing is shown
/// twice.
class BackgroundNotifications {
  BackgroundNotifications._();

  static const taskName = 'skillserve.notification-check';
  static const _cursorKey = 'skillserve.background.after';
  static const _seenKey = 'skillserve.background.seenIds';
  static const foregroundKey = 'skillserve.app.foreground';
  static const _foregroundAtKey = 'skillserve.app.foregroundAt';

  /// A "foreground" mark older than this is ignored: Android can kill an app
  /// on screen without it ever reporting that it left.
  static const _foregroundStaleAfter = Duration(minutes: 60);

  static const _channel = AndroidNotificationDetails(
    'skillserve_updates',
    'SkillServe updates',
    channelDescription: 'Bookings, messages and account updates while the app is closed',
    importance: Importance.high,
    priority: Priority.high,
    // White silhouette for the status bar (res/drawable/ic_stat_notification.xml).
    icon: 'ic_stat_notification',
  );

  static final _plugin = FlutterLocalNotificationsPlugin();

  /// A route the user asked to open by tapping a notification; the router
  /// listens and navigates once the app is ready.
  static final ValueNotifier<String?> tappedRoute = ValueNotifier(null);

  static bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Once, at app start.
  static Future<void> initialize() async {
    if (!_supported) return;
    await _initPlugin(onTap: (payload) => tappedRoute.value = payload);
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      tappedRoute.value = launch!.notificationResponse?.payload;
    }
    await Workmanager().initialize(backgroundNotificationDispatcher);
  }

  /// After sign-in: ask for permission, get the background token and start
  /// the periodic check. Safe to call again; it keeps the running schedule.
  static Future<void> enable() async {
    if (!_supported) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      if (await TokenStorage.readBackgroundToken() == null) {
        final response = await ApiClient.instance.dio.post('/client/v1/notifications/background-token');
        final token = (response.data['data'] as Map)['token'] as String?;
        if (token == null) return;
        await TokenStorage.saveBackgroundToken(token);
      }

      // Start from now: what is already unread is in the in-app feed.
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_cursorKey) == null) {
        await prefs.setString(_cursorKey, DateTime.now().toUtc().toIso8601String());
      }

      await Workmanager().registerPeriodicTask(
        taskName,
        taskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (e) {
      // Background delivery is a convenience; the in-app feed still works.
      debugPrint('[BackgroundNotifications] not enabled: $e');
    }
  }

  /// On sign-out: stop the check. The token itself is cleared by
  /// TokenStorage.clear() and revoked by the server's logout.
  static Future<void> disable() async {
    if (!_supported) return;
    try {
      await Workmanager().cancelByUniqueName(taskName);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cursorKey);
      await prefs.remove(_seenKey);
    } catch (_) {}
  }

  /// Whether the app is on screen, written by the notification poller —
  /// on every lifecycle change and whenever a notification arrives in-app,
  /// which keeps the mark fresh during long sessions.
  static Future<void> setForeground(bool foreground) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(foregroundKey, foreground);
      await prefs.setInt(_foregroundAtKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  static bool _isForeground(SharedPreferences prefs) {
    if (prefs.getBool(foregroundKey) != true) return false;
    final at = prefs.getInt(_foregroundAtKey);
    // No timestamp: written by a test or an older build; trust the flag.
    if (at == null) return true;
    return DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(at)) < _foregroundStaleAfter;
  }

  static Future<void> _initPlugin({void Function(String? payload)? onTap}) => _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_notification'),
        ),
        onDidReceiveNotificationResponse: onTap == null ? null : (response) => onTap(response.payload),
      );

  /// One background check. Returns true so WorkManager does not retry: a
  /// missed check is simply picked up by the next one.
  static Future<bool> check({Dio? client}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await TokenStorage.readBackgroundToken();
    if (token == null) return true;

    final after = prefs.getString(_cursorKey);
    final dio = client ??
        Dio(BaseOptions(
          baseUrl: AppConfig.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        ));

    final List<dynamic> items;
    try {
      final response = await dio.get(
        '/client/v1/notifications/background',
        queryParameters: {if (after != null) 'after': after},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      items = response.data['data'] as List? ?? const [];
    } on DioException catch (e) {
      // 401/403: signed out, suspended or token revoked. Stop until the app
      // signs in again and enables it.
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        try {
          await Workmanager().cancelByUniqueName(taskName);
        } catch (_) {}
      }
      return true;
    }

    final seen = prefs.getStringList(_seenKey) ?? const [];
    final notifications = [
      for (final item in items)
        if (item is Map<String, dynamic>) NotificationModel.fromJson(item),
    ].where((n) => !seen.contains(n.id)).toList();
    if (notifications.isEmpty) return true;

    // On screen, Reverb already showed these; only move the cursor.
    if (!_isForeground(prefs)) {
      await _initPlugin();
      for (final n in notifications) {
        await _plugin.show(
          id: n.id.hashCode & 0x7fffffff,
          title: n.title.isEmpty ? 'SkillServe' : n.title,
          body: n.message,
          notificationDetails: const NotificationDetails(android: _channel),
          payload: n.destination ?? '/notifications',
        );
      }
    }

    final newest = items.whereType<Map<String, dynamic>>().map((i) => i['created_at'] as String?).whereType<String>().fold<String?>(
          after,
          (latest, value) => latest == null || DateTime.parse(value).isAfter(DateTime.parse(latest)) ? value : latest,
        );
    if (newest != null) await prefs.setString(_cursorKey, newest);
    await prefs.setStringList(_seenKey, [...seen, ...notifications.map((n) => n.id)].reversed.take(50).toList().reversed.toList());
    return true;
  }
}

/// WorkManager's entry point, run in a background isolate.
@pragma('vm:entry-point')
void backgroundNotificationDispatcher() {
  Workmanager().executeTask((task, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (task != BackgroundNotifications.taskName) return true;
    try {
      return await BackgroundNotifications.check();
    } catch (e) {
      debugPrint('[BackgroundNotifications] check failed: ${jsonEncode(e.toString())}');
      return true;
    }
  });
}
