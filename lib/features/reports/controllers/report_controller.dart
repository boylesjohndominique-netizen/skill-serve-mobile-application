import 'package:flutter/foundation.dart';
import '../../../core/utils/api_error.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

/// Drives the file-a-report flow, the My Reports and My Disputes lists, and
/// booking disputes.
class ReportController extends ChangeNotifier {
  ReportController({ReportService? service}) : _reportService = service ?? ReportService();

  final ReportService _reportService;

  List<ReportModel> reports = [];
  List<DisputeModel> disputes = [];
  bool isSubmitting = false;

  /// Reports and disputes are separate cases on separate screens, read from
  /// separate endpoints — so each list keeps its own loading state and error.
  bool isLoadingReports = false;
  bool isLoadingDisputes = false;
  String? reportsError;
  String? disputesError;

  /// Set by a failed submit.
  String? errorMessage;

  /// Loads the complaints this account has filed, for My Reports.
  Future<void> loadReports() async {
    isLoadingReports = true;
    reportsError = null;
    notifyListeners();
    try {
      reports = await _reportService.getMyReports();
    } catch (e) {
      reports = [];
      reportsError = apiErrorMessage(e, 'Unable to load your reports.');
    }
    isLoadingReports = false;
    notifyListeners();
  }

  /// Loads the booking disputes this account is a party to, for My Disputes.
  Future<void> loadDisputes() async {
    isLoadingDisputes = true;
    disputesError = null;
    notifyListeners();
    try {
      disputes = await _reportService.getMyDisputes();
    } catch (e) {
      disputes = [];
      disputesError = apiErrorMessage(e, 'Unable to load your disputes.');
    }
    isLoadingDisputes = false;
    notifyListeners();
  }

  /// Re-reads reports and disputes without a loading state — support acted
  /// on one (a decision, a dispute update) while the user may be looking.
  /// Keeps what is on screen if the refresh fails.
  Future<void> refreshQuietly() async {
    try {
      final results = await Future.wait([_reportService.getMyReports(), _reportService.getMyDisputes()]);
      reports = results[0] as List<ReportModel>;
      disputes = results[1] as List<DisputeModel>;
      reportsError = null;
      disputesError = null;
      notifyListeners();
    } catch (_) {
      // The next visit to My Reports or My Disputes loads them again.
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
  /// from My Disputes).
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
