import 'package:dio/dio.dart';

import '../../../core/services/api_client.dart';
import '../models/identity_verification_model.dart';

/// National ID verification for the signed-in account
/// (api-docs/modules/identity-verification.md):
/// - GET  /api/client/v1/identity-verification
/// - POST /api/client/v1/identity-verification  (multipart)
/// - GET  /api/client/v1/transaction-eligibility
///
/// Customers and providers use the same endpoints: identity is identity. This
/// is separate from provider verification, which proves a provider is a
/// legitimate tradesperson.
class IdentityService {
  static const _path = '/client/v1/identity-verification';
  static const _eligibilityPath = '/client/v1/transaction-eligibility';

  Future<IdentityVerification> get() async {
    final response = await ApiClient.instance.dio.get(_path);
    return IdentityVerification.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<TransactionEligibility> eligibility() async {
    final response = await ApiClient.instance.dio.get(_eligibilityPath);
    return TransactionEligibility.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Submits the card for review.
  ///
  /// [idNumber] is sent as typed; the API strips everything but digits, so
  /// "1234-5678-9012-3456" and the bare digits are the same card. It is sent
  /// once and never stored on the device.
  Future<IdentityVerification> submit({
    required String idNumber,
    required String fullName,
    required DateTime birthdate,
    required List<PendingIdentityDocument> documents,
    void Function(double progress)? onProgress,
  }) async {
    final form = FormData();
    form.fields
      ..add(MapEntry('id_number', idNumber))
      ..add(MapEntry('full_name', fullName.trim()))
      ..add(MapEntry('birthdate', _isoDate(birthdate)));

    for (var i = 0; i < documents.length; i++) {
      final document = documents[i];
      form.fields.add(MapEntry('documents[$i][type]', document.type));
      form.files.add(MapEntry(
        'documents[$i][file]',
        MultipartFile.fromBytes(
          document.bytes,
          filename: document.fileName,
          contentType: _mediaType(document.fileName),
        ),
      ));
    }

    final response = await ApiClient.instance.dio.post(
      _path,
      data: form,
      onSendProgress:
          onProgress == null ? null : (sent, total) => onProgress(total <= 0 ? 0 : sent / total),
    );
    return IdentityVerification.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// `YYYY-MM-DD` — the API validates a date, not a timestamp.
  static String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DioMediaType _mediaType(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.pdf')) return DioMediaType('application', 'pdf');
    if (name.endsWith('.png')) return DioMediaType('image', 'png');
    return DioMediaType('image', 'jpeg');
  }
}
