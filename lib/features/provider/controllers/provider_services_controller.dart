import 'package:flutter/foundation.dart';
import '../../../core/utils/api_error.dart';
import '../models/provider_service_model.dart';
import '../services/provider_service_service.dart';

/// State for the provider's own services: list, submit, edit and delete.
class ProviderServicesController extends ChangeNotifier {
  final ProviderServiceService _service = ProviderServiceService();

  List<ProviderServiceModel> services = [];
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      services = await _service.getMyServices();
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to load your services.');
    }
    isLoading = false;
    notifyListeners();
  }

  /// Returns true when the service was submitted for approval.
  Future<bool> create(Map<String, dynamic> values) {
    return _save(() async {
      final created = await _service.create(values);
      services = [created, ...services];
    }, 'Unable to submit the service.');
  }

  /// Returns true when the changes were saved (and sent for approval).
  Future<bool> update(String id, Map<String, dynamic> values) {
    return _save(() async {
      final updated = await _service.update(id, values);
      services = [for (final s in services) s.id == id ? updated : s];
    }, 'Unable to save your changes.');
  }

  Future<bool> delete(String id) {
    return _save(() async {
      await _service.delete(id);
      services = services.where((s) => s.id != id).toList();
    }, 'Unable to delete the service.');
  }

  Future<bool> _save(Future<void> Function() action, String fallback) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      errorMessage = apiErrorMessage(e, fallback);
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
