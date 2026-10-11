import 'package:flutter/foundation.dart';

import '../../../core/utils/api_error.dart';
import '../models/commission_model.dart';
import '../services/commission_service.dart';

/// What the signed-in provider owes SkillServe, shared so the Commission
/// screen stays current: the notification poller reloads it when SkillServe
/// confirms or rejects a GCash payment, or settles a commission by hand,
/// instead of the provider having to pull to refresh.
class CommissionController extends ChangeNotifier {
  CommissionController({CommissionService? service}) : _service = service ?? CommissionService();

  final CommissionService _service;

  CommissionSummary? summary;
  bool isLoading = false;
  String? errorMessage;

  bool _signedIn = false;

  /// Follows the session: one provider's balance must never be left on
  /// screen for the next person to sign in.
  void onAuthChanged({required bool signedIn}) {
    if (_signedIn == signedIn) return;
    _signedIn = signedIn;
    if (signedIn) return;
    summary = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      summary = await _service.getSummary();
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to load your commission balance.');
    }
    isLoading = false;
    notifyListeners();
  }
}
