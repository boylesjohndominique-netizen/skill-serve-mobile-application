import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/feedback/app_snackbar.dart';
import '../../../core/services/background_notifications.dart';
import '../../../core/services/realtime_client.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../booking/controllers/booking_controller.dart';
import '../../booking/controllers/provider_booking_controller.dart';
import '../../identity/controllers/identity_controller.dart';
import '../../messaging/controllers/chat_controller.dart';
import '../../provider/controllers/commission_controller.dart';
import '../../provider/controllers/provider_services_controller.dart';
import '../../reports/controllers/report_controller.dart';
import '../../support/controllers/support_controller.dart';
import '../../settings/controllers/preferences_controller.dart';
import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';

/// Keeps notifications arriving while the app is open and signed in: listens
/// on the user's private realtime channel (instant), falls back to polling
/// while the WebSocket is down, pauses in the background, and shows a banner
/// for each new notification the user has not muted in Settings.
class NotificationPoller extends StatefulWidget {
  final Widget child;
  const NotificationPoller({super.key, required this.child});

  @override
  State<NotificationPoller> createState() => _NotificationPollerState();
}

class _NotificationPollerState extends State<NotificationPoller> with WidgetsBindingObserver {
  late final AuthController _auth;
  late final NotificationController _notifications;
  late final ChatController _chat;
  final RealtimeClient _realtime = RealtimeClient.instance;
  String? _listeningUserId;
  String? _backgroundUserId;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth = context.read<AuthController>();
    _notifications = context.read<NotificationController>();
    _chat = context.read<ChatController>();
    _auth.addListener(_sync);
    _notifications.addListener(_showIncoming);
    _realtime.isConnected.addListener(_onRealtimeStatus);
    BackgroundNotifications.setForeground(true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth.removeListener(_sync);
    _notifications.removeListener(_showIncoming);
    _realtime.isConnected.removeListener(_onRealtimeStatus);
    _realtime.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    // The background check posts system notifications only while the app is
    // off screen; on screen, Reverb and the banner below already show them.
    BackgroundNotifications.setForeground(_foreground);
    _sync();
  }

  bool get _signedIn => _auth.status == AuthStatus.authenticated && _auth.currentUser != null;

  void _sync() {
    final userId = _signedIn ? _auth.currentUser!.id : null;

    // Closed-app notifications follow the session, not the lifecycle.
    if (userId != _backgroundUserId) {
      _backgroundUserId = userId;
      userId == null ? BackgroundNotifications.disable() : BackgroundNotifications.enable();
    }

    if (userId == null || !_foreground) {
      if (_listeningUserId != null) {
        _realtime.disconnect();
        _listeningUserId = null;
      }
      if (userId == null) {
        if (_notifications.isPolling || _notifications.unreadCount > 0) _notifications.reset();
      } else {
        _notifications.stopPolling();
      }
      return;
    }

    if (_listeningUserId != userId) {
      _realtime.disconnect();
      _realtime.listen('App.Models.User.$userId', 'client.notification.created', (_) {
        _notifications.onRealtimeNotification();
      });
      // Archived, restored or deleted on another of the user's devices.
      _realtime.listen('App.Models.User.$userId', 'client.notifications.changed', (_) {
        _notifications.onRemoteChange();
      });
      // Chat content rides the same channel, so an open conversation updates
      // the moment the other party sends something. Deliberately separate from
      // the notification above: muting message alerts must not stop a
      // conversation the user is looking at from moving.
      _realtime.listen('App.Models.User.$userId', 'client.message.created', (data) {
        final bookingId = data['booking_id']?.toString();
        final message = data['message'];
        if (bookingId != null && message is Map<String, dynamic>) {
          _chat.onRealtimeMessage(bookingId, message);
        }
      });
      _listeningUserId = userId;
    }
    _notifications.startPolling();
    // The Messages badge has to be right before the tab is ever opened.
    _chat.refreshUnreadCount();
  }

  void _onRealtimeStatus() {
    final connected = _realtime.isConnected.value;
    _notifications.realtimeConnected = connected;
    // Catch up on anything sent while the socket was down.
    if (connected) {
      _notifications.checkForNew();
      _chat.refreshUnreadCount();
    }
  }

  void _showIncoming() {
    final notification = _notifications.incoming;
    if (notification == null || !mounted) return;
    _notifications.clearIncoming();
    // Still on screen: keep the background check from repeating this one.
    if (_foreground) BackgroundNotifications.setForeground(true);

    // An administrator changed the account (verification, provider
    // suspension): refresh it so status cards and guards are current.
    final rawType = (notification.data['type'] ?? '').toString();
    if (notification.type == NotificationType.verification ||
        rawType == 'provider_status' ||
        rawType == 'account_status') {
      _auth.refreshCurrentUser();
    }
    // A National ID decision also changes what the account may do, which the
    // eligibility banner and the identity screen show.
    if (rawType == 'identity_verification') {
      final identity = context.read<IdentityController>();
      identity.refreshEligibility();
      identity.load();
    }

    // A commission settled, waived, or a GCash payment confirmed or rejected:
    // what the provider owes and whether they may take new work both moved.
    if (_auth.isProvider && (rawType == 'commission_remittance' || rawType == 'booking_commission')) {
      context.read<IdentityController>().refreshEligibility();
      context.read<CommissionController>().load();
    }

    // Service moderation (approved, rejected, …) changes the provider's list.
    if (notification.type == NotificationType.service) {
      context.read<ProviderServicesController>().load();
    }

    // A booking that was accepted, started, completed or cancelled moves to a
    // different tab, so the list behind the banner is reloaded. This happens
    // before the preference gate: muting the banner silences the alert, it
    // does not mean the screen should keep showing a stale status.
    if (notification.type == NotificationType.booking) {
      if (_auth.isProvider) {
        context.read<ProviderBookingController>().loadProviderBookings();
      } else {
        context.read<BookingController>().loadClientBookings();
      }
    }

    // Support replied to or resolved a ticket: an open thread shows the
    // reply at once, and the inbox moves it.
    if (rawType.startsWith('support_ticket')) {
      context.read<SupportController>().refreshQuietly();
    }

    // A report decided or a dispute moved: My Reports and My Disputes follow,
    // and a dispute decision can change the booking too.
    if (rawType == 'report_update' || rawType == 'dispute_update') {
      context.read<ReportController>().refreshQuietly();
    }
    if (rawType == 'dispute_update') {
      if (_auth.isProvider) {
        context.read<ProviderBookingController>().loadProviderBookings();
      } else {
        context.read<BookingController>().loadClientBookings();
      }
    }

    if (!_enabledInPreferences(notification.type)) return;

    final text = notification.message.isEmpty ? notification.title : '${notification.title}: ${notification.message}';
    AppSnackbar.success(context, text);
  }

  bool _enabledInPreferences(NotificationType type) {
    final preferences = context.read<PreferencesController>();
    return switch (type) {
      NotificationType.booking => preferences.bookingNotifications,
      NotificationType.message => preferences.messageNotifications,
      NotificationType.service || NotificationType.verification => preferences.serviceNotifications,
      // Announcements, promos and system notices all sit behind the one
      // "Announcements" switch, which is how the API groups them too.
      NotificationType.announcement ||
      NotificationType.promo ||
      NotificationType.system =>
        preferences.announcementNotifications,
    };
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Bell button with the live unread-notification count.
class NotificationBellIcon extends StatelessWidget {
  final Widget icon;
  const NotificationBellIcon({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    final count = context.select<NotificationController, int>((c) => c.unreadCount);
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: icon,
    );
  }
}
