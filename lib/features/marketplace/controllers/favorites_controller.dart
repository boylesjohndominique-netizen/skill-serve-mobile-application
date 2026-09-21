import 'package:flutter/foundation.dart';

import '../../../core/utils/api_error.dart';
import '../models/provider_model.dart';
import '../services/favorites_service.dart';

/// The customer's saved providers, kept on the server so they survive
/// restarts and follow the account to another device.
///
/// Follows the session: a signed-in customer's list is loaded, and signing
/// out (or signing in as a provider) clears it. Toggling is optimistic — the
/// heart flips at once and flips back if the server refuses.
class FavoritesController extends ChangeNotifier {
  FavoritesController({FavoritesService? service}) : _service = service ?? FavoritesService();

  final FavoritesService _service;

  final Set<String> _favoriteIds = {};
  List<ProviderModel> providers = [];
  bool isLoading = false;
  String? errorMessage;
  bool _signedIn = false;

  /// Only a signed-in customer has favorites; guests are asked to sign in.
  bool get canSave => _signedIn;

  bool isFavorite(String providerId) => _favoriteIds.contains(providerId);

  Set<String> get favoriteIds => Set.unmodifiable(_favoriteIds);

  /// Called whenever the session changes.
  Future<void> onAuthChanged({required bool signedInAsClient}) async {
    if (_signedIn == signedInAsClient) return;
    _signedIn = signedInAsClient;
    if (signedInAsClient) {
      await load();
    } else {
      _favoriteIds.clear();
      providers = [];
      errorMessage = null;
      notifyListeners();
    }
  }

  Future<void> load() async {
    if (!_signedIn) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      providers = await _service.list();
      _favoriteIds
        ..clear()
        ..addAll(providers.map((p) => p.id));
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to load your favorites.');
    }
    isLoading = false;
    notifyListeners();
  }

  /// Saves or removes [provider]. Returns false when the server refused or
  /// the user is not signed in as a customer, with the reason in
  /// [errorMessage]; the heart is then back where it was.
  Future<bool> toggle(ProviderModel provider) async {
    if (!_signedIn) {
      errorMessage = 'Sign in to save providers to your favorites.';
      return false;
    }

    final saving = !_favoriteIds.contains(provider.id);
    final previous = providers;
    _apply(provider, saving);

    try {
      saving ? await _service.add(provider.id) : await _service.remove(provider.id);
      return true;
    } catch (e) {
      _favoriteIds.remove(provider.id);
      providers = previous;
      if (!saving) _favoriteIds.add(provider.id);
      errorMessage = apiErrorMessage(
        e,
        saving ? 'Unable to save this provider.' : 'Unable to remove this provider.',
      );
      notifyListeners();
      return false;
    }
  }

  void _apply(ProviderModel provider, bool saving) {
    if (saving) {
      _favoriteIds.add(provider.id);
      providers = [provider, ...providers.where((p) => p.id != provider.id)];
    } else {
      _favoriteIds.remove(provider.id);
      providers = providers.where((p) => p.id != provider.id).toList();
    }
    errorMessage = null;
    notifyListeners();
  }
}
