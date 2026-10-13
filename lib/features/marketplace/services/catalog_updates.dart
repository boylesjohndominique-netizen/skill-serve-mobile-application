import 'package:flutter/foundation.dart';

/// Tells every marketplace screen that the public catalog changed — a
/// provider published or edited a service, an administrator approved one, a
/// provider's profile or rating moved — so Home, Explore and the profile
/// pages refetch instead of showing what was true when they first loaded.
///
/// Fed by `MarketplaceLiveSync` from the backend's public `marketplace`
/// channel (`marketplace.changed`), and by catch-up refreshes after the app
/// was in the background or the WebSocket was down.
class CatalogUpdates extends ChangeNotifier {
  CatalogUpdates();

  /// The app-wide instance the live sync feeds and the screens follow.
  static final CatalogUpdates instance = CatalogUpdates();

  /// What the latest change touched (`services`, `providers`, `categories`,
  /// `reviews`, `settings`). Empty means "unknown — refresh everything".
  Set<String> lastResources = const {};

  void changed([Iterable<String> resources = const []]) {
    lastResources = resources.toSet();
    notifyListeners();
  }
}
