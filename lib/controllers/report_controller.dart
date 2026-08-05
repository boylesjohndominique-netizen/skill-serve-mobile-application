import 'package:flutter/foundation.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';

/// Drives the file-a-report flow and My Reports list.
class ReportController extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  List<ReportModel> reports = [];
  bool isLoading = false;
  bool isSubmitting = false;

  Future<void> loadMyReports() async {
    isLoading = true;
    notifyListeners();
    reports = await _reportService.getMyReports();
    isLoading = false;
    notifyListeners();
  }

  Future<ReportModel?> fileReport({
    required String reportedName,
    required String reason,
    required String details,
  }) async {
    isSubmitting = true;
    notifyListeners();
    final report = await _reportService.fileReport(
      reportedName: reportedName,
      reason: reason,
      details: details,
    );
    reports.insert(0, report);
    isSubmitting = false;
    notifyListeners();
    return report;
  }
}
