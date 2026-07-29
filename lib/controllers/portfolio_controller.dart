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
}
