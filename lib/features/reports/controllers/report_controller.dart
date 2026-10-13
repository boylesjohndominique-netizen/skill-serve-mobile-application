import 'package:flutter/foundation.dart';
import '../../../core/utils/api_error.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

/// Drives the file-a-report flow, the My Reports list and booking disputes.
class ReportController extends ChangeNotifier {
  ReportController({ReportService? service}) : _reportService = service ?? ReportService();

  final ReportService _reportService;

  List<ReportModel> reports = [];
  List<DisputeModel> disputes = [];
  bool isLoading = false;
  bool isSubmitting = false;

  /// Errors are tracked per list. The two come from separate endpoints, so one
  /// failing must neither blank the other nor let its tab claim to be empty
  /// when it simply could not be read.
  String? reportsError;
  String? disputesError;

  /// Set by a failed submit, and by a load that failed outright.
  String? errorMessage;

  /// True when neither list could be loaded — the only case worth replacing the
  /// whole screen with an error.
  bool get loadFailed => reportsError != null && disputesError != null;

  Future<void> loadMyReports() async {
    isLoading = true;
    reportsError = null;
    disputesError = null;
    errorMessage = null;
    notifyListeners();

    await Future.wait([
      _loadReports(),
      _loadDisputes(),
    ]);

    errorMessage = loadFailed ? reportsError : null;
    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadReports() async {
    try {
      reports = await _reportService.getMyReports();
    } catch (e) {
      reports = [];
      reportsError = apiErrorMessage(e, 'Unable to load your reports.');
    }
  }

  Future<void> _loadDisputes() async {
    try {
      disputes = await _reportService.getMyDisputes();
    } catch (e) {
      disputes = [];
      disputesError = apiErrorMessage(e, 'Unable to load your disputes.');
    }
  }

  /// Files a report about the other party on [bookingId], a review, a message
  /// or a service. Returns null and sets [errorMessage] when the API refuses it.
  Future<ReportModel?> fileReport({
    String? bookingId,
    String? reviewId,
    String? messageId,
    String? serviceId,
    String? providerId,
    required ReportReason reason,
    required String details,
    List<String> photoPaths = const [],
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final report = await _reportService.fileReport(
        photoPaths: photoPaths,
        bookingId: bookingId,
        reviewId: reviewId,
        messageId: messageId,
        serviceId: serviceId,
        providerId: providerId,
        reason: reason,
        details: details,
      );
      reports = [report, ...reports];
      return report;
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to file this report.');
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  /// Photos that could not be attached to the last dispute raised, so the
  /// screen can say so (the dispute itself stands; they can be added later
  /// from My Reports).
  int unsentDisputePhotos = 0;

  /// Raises a dispute on a booking, then attaches [photoPaths] as evidence.
  /// Returns null and sets [errorMessage] when the API refuses the dispute —
  /// most often because the job cannot be disputed in its current status, or
  /// already is.
  Future<DisputeModel?> raiseDispute({
    required String bookingId,
    required String reason,
    List<String> photoPaths = const [],
  }) async {
    isSubmitting = true;
    errorMessage = null;
    unsentDisputePhotos = 0;
    notifyListeners();
    try {
      var dispute = await _reportService.raiseDispute(
        bookingId: bookingId,
        reason: reason,
      );
      for (final path in photoPaths) {
        try {
          dispute = await _reportService.uploadDisputeEvidence(bookingId: bookingId, filePath: path);
        } catch (_) {
          unsentDisputePhotos++;
        }
      }
      disputes = [dispute, ...disputes.where((d) => d.bookingId != dispute.bookingId)];
      return dispute;
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to raise this dispute.');
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  /// Attaches a photo to an open dispute. Returns false and sets
  /// [errorMessage] when the API refuses it.
  Future<bool> addDisputeEvidence({
    required String bookingId,
    required String filePath,
    String? caption,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final updated = await _reportService.uploadDisputeEvidence(
        bookingId: bookingId,
        filePath: filePath,
        caption: caption,
      );
      disputes = [
        for (final d in disputes) d.bookingId == updated.bookingId ? updated : d,
      ];
      return true;
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to upload this photo.');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}
