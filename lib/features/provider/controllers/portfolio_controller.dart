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

  /// Adds a work sample and puts it at the top, matching the API's order.
  Future<bool> add({
    required String title,
    required String description,
    required String imagePath,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final created = await _service.uploadPortfolioItem(
        title: title,
        description: description,
        imagePath: imagePath,
      );
      items = [created, ...items];
      return true;
    } catch (e) {
      errorMessage =
          apiErrorMessage(e, 'We could not upload that item.');
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
}
