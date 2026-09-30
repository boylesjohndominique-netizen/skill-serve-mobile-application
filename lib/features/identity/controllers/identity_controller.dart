import 'package:flutter/foundation.dart';

import '../../../core/utils/api_error.dart';
import '../models/identity_verification_model.dart';
import '../services/identity_service.dart';

/// Drives the National ID screens: the current status, the two card photos
/// captured but not yet sent, and the submission itself.
///
/// The card number is held only while the form is on screen and is cleared as
/// soon as it has been sent. It is never written to storage.
class IdentityController extends ChangeNotifier {
  IdentityController({IdentityService? service}) : _service = service ?? IdentityService();

  final IdentityService _service;

  IdentityVerification? verification;
  TransactionEligibility eligibility = TransactionEligibility.unknown;

  /// Keyed by document type, so re-capturing a side replaces it rather than
  /// adding a second copy.
  final Map<String, PendingIdentityDocument> captured = {};

  bool isLoading = false;
  bool isSubmitting = false;
  double progress = 0;
  String? errorMessage;

  bool get hasFront => captured.containsKey(PendingIdentityDocument.frontType);
  bool get hasBack => captured.containsKey(PendingIdentityDocument.backType);

  /// Both sides of the card are required before the form can be sent.
  bool get canSubmit => hasFront && hasBack && !isSubmitting;

  bool get isVerified => verification?.isVerified ?? false;
  bool get isPending => verification?.isPending ?? false;

  /// Whether this account must verify before it can transact. Accounts created
  /// before the platform's cutover are exempt, which only the API knows.
  bool get isRequired => eligibility.identityRequired;

  bool _signedIn = false;

  /// Follows the session. Verification and eligibility are decided per
  /// account, so one account's answer must never be left on screen for the
  /// next person to sign in.
  Future<void> onAuthChanged({required bool signedIn}) async {
    if (_signedIn == signedIn) return;
    _signedIn = signedIn;
    if (signedIn) {
      await refreshEligibility();
      return;
    }
    verification = null;
    eligibility = TransactionEligibility.unknown;
    captured.clear();
    errorMessage = null;
    notifyListeners();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      // Both in one pass: the status drives the screen, the eligibility tells
      // it whether skipping is allowed.
      final results = await Future.wait([
        _service.get(),
        _service.eligibility(),
      ]);
      verification = results[0] as IdentityVerification;
      eligibility = results[1] as TransactionEligibility;
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to load your verification status.');
    }
    isLoading = false;
    notifyListeners();
  }

  /// Refreshes only the eligibility, for callers that just need to know
  /// whether an action is currently allowed.
  Future<void> refreshEligibility() async {
    if (!_signedIn) return;
    try {
      eligibility = await _service.eligibility();
      notifyListeners();
    } catch (_) {
      // Advisory only: a failure here must not block the screen, because the
      // API re-checks on every protected action anyway.
    }
  }

  /// Stores a captured side; returns an error message instead when it cannot
  /// be sent.
  String? capture(PendingIdentityDocument document) {
    final extension = document.fileName.split('.').last.toLowerCase();
    if (!PendingIdentityDocument.allowedExtensions.contains(extension)) {
      return 'Use a JPG or PNG photo.';
    }
    if (document.bytes.length > PendingIdentityDocument.maxBytes) {
      return 'That photo is larger than 10 MB. Try again with a smaller one.';
    }
    captured[document.type] = document;
    errorMessage = null;
    notifyListeners();
    return null;
  }

  void remove(String type) {
    captured.remove(type);
    notifyListeners();
  }

  /// Sends the card for review. Returns true when it was accepted.
  Future<bool> submit({
    required String idNumber,
    required String fullName,
    required DateTime birthdate,
  }) async {
    if (!canSubmit) return false;

    isSubmitting = true;
    progress = 0;
    errorMessage = null;
    notifyListeners();

    try {
      verification = await _service.submit(
        idNumber: idNumber,
        fullName: fullName,
        birthdate: birthdate,
        documents: [
          captured[PendingIdentityDocument.frontType]!,
          captured[PendingIdentityDocument.backType]!,
          if (captured[PendingIdentityDocument.selfieType] != null)
            captured[PendingIdentityDocument.selfieType]!,
        ],
        onProgress: (value) {
          progress = value;
          notifyListeners();
        },
      );
      // The photos are no longer needed once the API has them.
      captured.clear();
      await refreshEligibility();
      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to submit your National ID.');
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }
}
