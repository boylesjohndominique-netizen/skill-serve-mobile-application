import 'package:flutter/foundation.dart';
import '../models/portfolio_model.dart';
import '../services/portfolio_service.dart';

class PortfolioController extends ChangeNotifier {
  final PortfolioService _service = PortfolioService();

  List<PortfolioModel> items = [];
  bool isLoading = false;

  Future<void> load(String providerId) async {
    isLoading = true;
    notifyListeners();
    items = await _service.getPortfolio(providerId);
    isLoading = false;
    notifyListeners();
  }

  /// Marks a rejected item back to pending for admin re-review.
  Future<void> resubmit(String itemId) async {
    await _service.resubmitPortfolioItem(itemId);
    items = [
      for (final item in items)
        item.id == itemId
            ? PortfolioModel(
                id: item.id,
                providerId: item.providerId,
                image: item.image,
                title: item.title,
                description: item.description,
                status: 'pending',
              )
            : item,
    ];
    notifyListeners();
  }
}
