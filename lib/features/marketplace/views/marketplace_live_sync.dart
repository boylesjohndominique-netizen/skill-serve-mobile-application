import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/services/realtime_client.dart';
import '../services/catalog_updates.dart';

/// Keeps the marketplace live while the app is on screen: listens on the
/// backend's public `marketplace` channel and turns each `marketplace.changed`
/// into a [CatalogUpdates] signal the screens refetch on.
///
/// Nothing is missed while the socket cannot deliver: returning to the app,
/// and the socket coming back, each trigger one catch-up refresh, and while
/// the socket is down the catalog is re-checked every [fallbackInterval].
class MarketplaceLiveSync extends StatefulWidget {
  final Widget child;

  /// Public channel and event the backend broadcasts catalog changes on
  /// (`App\Shared\Realtime\MarketplaceChanged`).
  static const channel = 'marketplace';
  static const event = 'marketplace.changed';

  /// How often to re-check the catalog while the socket is down.
  static const fallbackInterval = Duration(seconds: 60);

  const MarketplaceLiveSync({super.key, required this.child});

  @override
  State<MarketplaceLiveSync> createState() => _MarketplaceLiveSyncState();
}

class _MarketplaceLiveSyncState extends State<MarketplaceLiveSync> with WidgetsBindingObserver {
  final RealtimeClient _realtime = RealtimeClient.instance;
  final CatalogUpdates _updates = CatalogUpdates.instance;

  /// Several writes in a row (a service and its provider's counters) arrive
  /// as separate events; one refetch covers them all.
  static const _coalesce = Duration(milliseconds: 400);

  Timer? _debounce;
  Timer? _fallback;
  final Set<String> _pending = {};
  bool _listening = false;
  bool _wasConnected = false;

  /// The first connection is not a reconnect: the screens are loading anyway.
  bool _connectedBefore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _realtime.isConnected.addListener(_onConnection);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _realtime.isConnected.removeListener(_onConnection);
    _stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final wasListening = _listening;
      _start();
      // Changes made while the app was away were never delivered.
      if (!wasListening) _notify(const {});
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _stop();
    }
  }

  void _start() {
    if (_listening) return;
    _listening = true;
    _realtime.listenPublic(MarketplaceLiveSync.channel, MarketplaceLiveSync.event, (data) {
      final resources = data['resources'];
      _notify(resources is List ? resources.map((r) => '$r') : const []);
    });
    _fallback = Timer.periodic(MarketplaceLiveSync.fallbackInterval, (_) {
      if (!_realtime.isConnected.value) _notify(const {});
    });
  }

  void _stop() {
    if (!_listening) return;
    _listening = false;
    _realtime.unlistenPublic(MarketplaceLiveSync.channel);
    _fallback?.cancel();
    _fallback = null;
    _debounce?.cancel();
    _pending.clear();
  }

  /// The socket came back after a drop: catch up on what it missed.
  void _onConnection() {
    final connected = _realtime.isConnected.value;
    if (connected && !_wasConnected && _connectedBefore && _listening) _notify(const {});
    if (connected) _connectedBefore = true;
    _wasConnected = connected;
  }

  /// [resources] empty means "unknown", which refreshes everything.
  void _notify(Iterable<String> resources) {
    final everything = resources.isEmpty;
    if (everything) {
      _pending.clear();
    } else if (!_pending.contains('*')) {
      _pending.addAll(resources);
    }
    if (everything) _pending.add('*');

    _debounce?.cancel();
    _debounce = Timer(_coalesce, () {
      final changed = _pending.contains('*') ? const <String>{} : Set.of(_pending);
      _pending.clear();
      _updates.changed(changed);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
