import '../data/mock/mock_data.dart';
import '../models/report_model.dart';
import 'api_client.dart';

/// Placeholder service for reports (complaints / disputes).
class ReportService {
  // GET /reports/mine
  Future<List<ReportModel>> getMyReports() async {
    await simulateNetworkDelay();
    return MockData.reports;
  }

  // POST /reports
  Future<ReportModel> fileReport({
    required String reportedName,
    required String reason,
    required String details,
  }) async {
    await simulateNetworkDelay(ms: 700);
    return ReportModel(
      id: 'RP-${DateTime.now().millisecondsSinceEpoch}',
      reporterName: MockData.currentClient.fullName,
      reportedName: reportedName,
      reason: reason,
      details: details,
      status: ReportStatus.open,
      createdAt: DateTime.now(),
      updates: [
        ReportUpdate(
          label: 'Report filed',
          at: DateTime.now(),
          status: 'open',
        ),
      ],
    );
  }
}
