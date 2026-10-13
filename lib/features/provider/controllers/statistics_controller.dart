import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../marketplace/services/catalog_updates.dart';
import '../models/provider_statistics_model.dart';
import '../services/statistics_service.dart';

/// Drives the provider's Statistics screen and keeps it live: it refetches
/// when the provider's bookings change ([bookingChanges] — the booking list
/// that booking notifications reload), when the catalog changes (a new
/// review moves the rating), and every [refreshEvery] while it is open.
/// Refreshes are silent: the numbers stay on screen until new ones arrive.
class StatisticsController extends ChangeNotifier {
  StatisticsController({
    StatisticsService? service,
    Listenable? bookingChanges,
    CatalogUpdates? updates,
    this.refreshEvery = const Duration(seconds: 60),
  })  : _service = service ?? StatisticsService(),
        _bookingChanges = bookingChanges,
        _updates = updates ?? CatalogUpdates.instance {
    _bookingChanges?.addListener(_refresh);
    _updates.addListener(_refresh);
  }

  final StatisticsService _service;
  final Listenable? _bookingChanges;
  final CatalogUpdates _updates;
  final Duration refreshEvery;

  /// Chart windows the screen offers.
  static const periods = [3, 6, 12];

  ProviderStatistics? statistics;
  int months = 6;
  bool isLoading = false;
  String? error;

  Timer? _timer;
  int _requestId = 0;
  bool _disposed = false;

  Future<void> load() => _load(silent: false);

  Future<void> setMonths(int value) async {
    if (value == months) return;
    months = value;
    await _load(silent: statistics != null);
  }

  void _refresh() {
    if (statistics != null) _load(silent: true);
  }

  Future<void> _load({required bool silent}) async {
    final requestId = ++_requestId;
    if (!silent) {
      isLoading = true;
      error = null;
      _notify();
    }
    try {
      final loaded = await _service.getStatistics(months: months);
      if (requestId != _requestId) return;
      statistics = loaded;
      error = null;
    } catch (_) {
      if (requestId != _requestId) return;
      // A failed background refresh keeps the numbers already shown.
      if (statistics == null) error = 'We could not load your statistics. Check your connection and try again.';
    }
    isLoading = false;
    _schedule();
    _notify();
  }

  void _schedule() {
    _timer?.cancel();
    if (!_disposed) _timer = Timer(refreshEvery, _refresh);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _bookingChanges?.removeListener(_refresh);
    _updates.removeListener(_refresh);
    super.dispose();
  }
}
