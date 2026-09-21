import 'package:dio/dio.dart';

import '../../../core/services/api_client.dart';
import '../models/verification_document_model.dart';

/// The signed-in provider's verification (api-docs/modules/provider-verification.md):
/// - GET  /api/client/v1/provider/verification
/// - POST /api/client/v1/provider/verification  (multipart: documents[i][type], documents[i][file], notes)
class VerificationService {
  static const _path = '/client/v1/provider/verification';

  Future<ProviderVerification> get() async {
    final response = await ApiClient.instance.dio.get(_path);
    return ProviderVerification.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Uploads [documents] for review. [onProgress] gets 0–1 as bytes go out.
  Future<ProviderVerification> submit(
    List<PendingVerificationDocument> documents, {
    String? notes,
    void Function(double progress)? onProgress,
  }) async {
    final form = FormData();
    for (var i = 0; i < documents.length; i++) {
      final document = documents[i];
      form.fields.add(MapEntry('documents[$i][type]', document.type));
      form.files.add(MapEntry(
        'documents[$i][file]',
        MultipartFile.fromBytes(document.bytes, filename: document.fileName, contentType: _mediaType(document.fileName)),
      ));
    }
    if (notes != null && notes.trim().isNotEmpty) form.fields.add(MapEntry('notes', notes.trim()));

    final response = await ApiClient.instance.dio.post(
      _path,
      data: form,
      onSendProgress: onProgress == null ? null : (sent, total) => onProgress(total <= 0 ? 0 : sent / total),
    );
    return ProviderVerification.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  static DioMediaType _mediaType(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.pdf')) return DioMediaType('application', 'pdf');
    if (name.endsWith('.png')) return DioMediaType('image', 'png');
    return DioMediaType('image', 'jpeg');
  }
}
