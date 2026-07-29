import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/provider_model.dart';
import '../services/service_service.dart';

/// Drives Browse Services / Categories / Search across Guest and Client.
class MarketplaceController extends ChangeNotifier {
  final ServiceService _service = ServiceService();

  List<CategoryModel> categories = [];
  List<ProviderModel> providers = [];
  bool isLoading = false;
  String selectedCategory = 'All';
  String searchQuery = '';

  Future<void> loadInitial() async {
    isLoading = true;
    notifyListeners();
    categories = await _service.getCategories();
    providers = await _service.getProviders();
    isLoading = false;
    notifyListeners();
  }

  Future<void> filterByCategory(String category) async {
    selectedCategory = category;
    isLoading = true;
    notifyListeners();
    providers = await _service.getProviders(category: category, search: searchQuery);
    isLoading = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    searchQuery = query;
    isLoading = true;
    notifyListeners();
    providers = await _service.getProviders(category: selectedCategory, search: query);
    isLoading = false;
    notifyListeners();
  }
}
