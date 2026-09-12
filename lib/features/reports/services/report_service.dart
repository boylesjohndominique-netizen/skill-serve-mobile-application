import '../models/report_model.dart';

/// Service for reports (complaints / disputes).
///
/// No documented client endpoints for reports. These methods will
/// throw [UnsupportedError] until the backend documents client report routes.
class ReportService {
  // No documented client endpoint.
  Future<List<ReportModel>> getMyReports() async {
    throw UnsupportedError('Client report endpoints are not documented.');
  }

  // No documented client endpoint.
  Future<ReportModel> fileReport({
    required String reportedName,
    required String reason,
    required String details,
  }) async {
    throw UnsupportedError('Client report endpoints are not documented.');
  }
}
