import 'package:flutter/foundation.dart';

import '../../../core/utils/api_error.dart';
import '../models/verification_document_model.dart';
import '../services/verification_service.dart';

/// Drives the verification screens: the current status from the API, the
/// files picked but not yet sent, and the upload itself.
class VerificationController extends ChangeNotifier {
  VerificationController({VerificationService? service}) : _service = service ?? VerificationService();

  final VerificationService _service;

  ProviderVerification? verification;
  final List<PendingVerificationDocument> picked = [];
  bool isLoading = false;
  bool isSubmitting = false;
  double progress = 0;
  String? errorMessage;

  static const maxPerSubmission = 5;

  bool get canAddMore => picked.length < maxPerSubmission;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      verification = await _service.get();
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to load your verification status.');
    }
    isLoading = false;
    notifyListeners();
  }

  /// Adds a picked file; returns an error message instead when it cannot be sent.
  String? add(PendingVerificationDocument document) {
    final extension = document.fileName.split('.').last.toLowerCase();
    if (!PendingVerificationDocument.allowedExtensions.contains(extension)) {
      return 'Choose a JPG, PNG or PDF file.';
    }
    if (document.bytes.length > PendingVerificationDocument.maxBytes) {
      return 'That file is larger than 10 MB.';
    }
    if (!canAddMore) return 'You can send up to $maxPerSubmission documents at a time.';
    picked.add(document);
    notifyListeners();
    return null;
  }

  void setType(int index, String type) {
    picked[index] = picked[index].withType(type);
    notifyListeners();
  }

  void remove(int index) {
    picked.removeAt(index);
    notifyListeners();
  }

  /// Sends the picked files. Returns true on success, with the new status in
  /// [verification]; otherwise [errorMessage] says why and the files stay picked.
  Future<bool> submit({String? notes}) async {
    if (picked.isEmpty || isSubmitting) return false;
    isSubmitting = true;
    progress = 0;
    errorMessage = null;
    notifyListeners();
    try {
      verification = await _service.submit(
        List.of(picked),
        notes: notes,
        onProgress: (value) {
          progress = value;
          notifyListeners();
        },
      );
      picked.clear();
      return true;
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to submit your documents. Please try again.');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
