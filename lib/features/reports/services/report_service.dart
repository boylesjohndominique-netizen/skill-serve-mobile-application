import 'package:dio/dio.dart';

import '../models/report_model.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/image_upload.dart';

/// Service for complaints and booking disputes — live API only.
///
/// Both are always about a booking: a report is about the *other party* on one
/// of your bookings, and a dispute is about the *job itself*.
///
/// Endpoints (api-docs/modules/client-reports.md, booking-disputes.md):
/// - GET   /api/client/v1/reports
/// - POST  /api/client/v1/reports
/// - GET   /api/client/v1/reports/{report}
/// - GET   /api/client/v1/disputes
/// - PATCH /api/client/v1/bookings/{booking}/dispute
/// - POST  /api/client/v1/bookings/{booking}/dispute/evidence
class ReportService {
  static const _reports = '/client/v1/reports';

  /// GET /api/client/v1/reports — the reports this account filed.
  Future<List<ReportModel>> getMyReports() async {
    final response = await ApiClient.instance.dio
        .get(_reports, queryParameters: {'per_page': 100});
    return [
      for (final item in response.data['data'] as List? ?? const [])
        ReportModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// GET /api/client/v1/reports/{report}
  Future<ReportModel> getReport(String id) async {
    final response = await ApiClient.instance.dio.get('$_reports/$id');
    return ReportModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/client/v1/reports — exactly one subject: the other party on
  /// [bookingId], a published [reviewId], or a [messageId] this account
  /// received. The API works out who that is, so no name is sent.
  Future<ReportModel> fileReport({
    String? bookingId,
    String? reviewId,
    String? messageId,
    required ReportReason reason,
    required String details,
  }) async {
    final subjects = [bookingId, reviewId, messageId].whereType<String>().length;
    assert(subjects == 1, 'A report names exactly one subject.');

    final response = await ApiClient.instance.dio.post(_reports, data: {
      if (bookingId != null) 'booking_id': int.parse(bookingId),
      if (reviewId != null) 'review_id': int.parse(reviewId),
      if (messageId != null) 'message_id': int.parse(messageId),
      'reason': reason.value,
      'description': details,
    });
    return ReportModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// GET /api/client/v1/disputes — disputes on this account's bookings.
  Future<List<DisputeModel>> getMyDisputes() async {
    final response = await ApiClient.instance.dio
        .get('/client/v1/disputes', queryParameters: {'per_page': 100});
    return [
      for (final item in response.data['data'] as List? ?? const [])
        DisputeModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// PATCH /api/client/v1/bookings/{booking}/dispute — raise a dispute on a
  /// job in progress or completed. A booking can be disputed only once.
  Future<DisputeModel> raiseDispute({
    required String bookingId,
    required String reason,
  }) async {
    final response = await ApiClient.instance.dio.patch(
      '/client/v1/bookings/$bookingId/dispute',
      data: {'reason': reason},
    );
    return DisputeModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/client/v1/bookings/{booking}/dispute/evidence — attach a photo
  /// to an open dispute. Up to five per dispute; administrators open them.
  Future<DisputeModel> uploadDisputeEvidence({
    required String bookingId,
    required String filePath,
    String? caption,
  }) async {
    final form = FormData.fromMap({
      'image': await imageMultipart(filePath),
      if (caption != null && caption.trim().isNotEmpty) 'caption': caption.trim(),
    });
    final response = await ApiClient.instance.dio.post(
      '/client/v1/bookings/$bookingId/dispute/evidence',
      data: form,
    );
    return DisputeModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
