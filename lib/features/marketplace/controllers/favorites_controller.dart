import 'package:flutter/foundation.dart';

/// Tracks favorited provider IDs client-side.
/// Placeholder only — sync with `POST/DELETE /favorites/:providerId` later.
class FavoritesController extends ChangeNotifier {
  final Set<String> _favoriteIds = {};

  bool isFavorite(String providerId) => _favoriteIds.contains(providerId);

  void toggle(String providerId) {
    if (_favoriteIds.contains(providerId)) {
      _favoriteIds.remove(providerId);
    } else {
      _favoriteIds.add(providerId);
    }
    notifyListeners();
  }

  Set<String> get favoriteIds => _favoriteIds;
}
