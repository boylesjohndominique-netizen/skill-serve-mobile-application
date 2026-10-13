import 'package:flutter/foundation.dart';

import '../models/portfolio_model.dart';
import '../services/portfolio_service.dart';
import '../../../core/utils/api_error.dart';

/// The signed-in provider's portfolio, and any provider's public gallery.
class PortfolioController extends ChangeNotifier {
  final PortfolioService _service;

  PortfolioController({PortfolioService? service})
      : _service = service ?? PortfolioService();

  List<PortfolioModel> items = [];
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  /// Loads the signed-in provider's own items.
  Future<void> loadMine() => _load(() => _service.getMyPortfolio());

  /// Loads another provider's public gallery.
  Future<void> load(String providerId) =>
      _load(() => _service.getPortfolio(providerId));

  Future<void> _load(Future<List<PortfolioModel>> Function() fetch) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      items = await fetch();
    } catch (_) {
      items = [];
      errorMessage = 'We could not load your portfolio. Pull down to retry.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// The item with [id], if loaded.
  PortfolioModel? find(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Adds a piece of work and puts it at the top, matching the API's order.
  Future<bool> add({
    required String title,
    required String description,
    required List<String> imagePaths,
  }) =>
      _save(
        () => _service.uploadPortfolioItem(title: title, description: description, imagePaths: imagePaths),
        'We could not upload that item.',
        insert: true,
      );

  /// Saves an edit in one go: the new text, then added photos, then the
  /// removed ones — in that order, so the item never drops to no photos.
  Future<bool> saveChanges(
    PortfolioModel item, {
    required String title,
    required String description,
    List<String> addedPaths = const [],
    List<String> removedPhotoIds = const [],
  }) =>
      _save(() async {
        var saved = item;
        if (title != item.title || description != item.description) {
          saved = await _service.updatePortfolioItem(item.id, title: title, description: description);
        }
        if (addedPaths.isNotEmpty) saved = await _service.addPhotos(item.id, addedPaths);
        for (final photoId in removedPhotoIds) {
          saved = await _service.removePhoto(item.id, photoId);
        }
        return saved;
      }, 'We could not save your changes.');

  Future<bool> _save(Future<PortfolioModel> Function() request, String fallback, {bool insert = false}) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final saved = await request();
      items = insert
          ? [saved, ...items]
          : [for (final item in items) item.id == saved.id ? saved : item];
      return true;
    } catch (e) {
      errorMessage = apiErrorMessage(e, fallback);
      // A partly applied edit is re-read, so the screen shows what was saved.
      if (!insert) await loadMine();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Removes an item, restoring it in the list if the server refuses.
  Future<bool> remove(String id) async {
    final previous = items;
    items = [for (final item in items) if (item.id != id) item];
    errorMessage = null;
    notifyListeners();
    try {
      await _service.removePortfolioItem(id);
      return true;
    } catch (e) {
      items = previous;
      errorMessage =
          apiErrorMessage(e, 'We could not remove that item.');
      notifyListeners();
      return false;
    }
  }

  /// Removes several items, one request each; returns how many went. Any the
  /// server refuses stay in the list, with [errorMessage] saying why.
  Future<int> removeMany(Iterable<String> ids) async {
    var removed = 0;
    String? failure;
    for (final id in ids.toList()) {
      if (await remove(id)) {
        removed++;
      } else {
        failure = errorMessage;
      }
    }
    if (failure != null) {
      errorMessage = failure;
      notifyListeners();
    }
    return removed;
  }
}
