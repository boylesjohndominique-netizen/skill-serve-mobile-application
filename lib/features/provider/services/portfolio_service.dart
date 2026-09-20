import 'package:dio/dio.dart';

import '../models/portfolio_model.dart';
import '../../../core/services/api_client.dart';

/// A provider's portfolio of work samples.
///
/// Endpoints:
/// - GET    /api/client/v1/provider/portfolio        (the signed-in provider's own)
/// - POST   /api/client/v1/provider/portfolio        (multipart upload)
/// - DELETE /api/client/v1/provider/portfolio/{item}
/// - GET    /api/client/v1/providers/{provider}      (public: `portfolio` on the profile)
class PortfolioService {
  static const _base = '/client/v1/provider/portfolio';

  /// The signed-in provider's own items, newest first.
  Future<List<PortfolioModel>> getMyPortfolio() async {
    final response = await ApiClient.instance.dio.get(_base);
    return _parse(response.data['data']);
  }

  /// Another provider's public gallery, read from their profile so the
  /// screen needs a single request.
  Future<List<PortfolioModel>> getPortfolio(String providerId) async {
    final response =
        await ApiClient.instance.dio.get('/client/v1/providers/$providerId');
    final data = response.data['data'] as Map<String, dynamic>;
    return _parse(data['portfolio']);
  }

  Future<PortfolioModel> uploadPortfolioItem({
    required String title,
    required String description,
    required String imagePath,
  }) async {
    final path = imagePath.replaceFirst('file://', '');
    final form = FormData.fromMap({
      'title': title,
      if (description.isNotEmpty) 'description': description,
      'image': await MultipartFile.fromFile(
        path,
        filename: _basename(path),
        contentType: _mediaTypeFor(path),
      ),
    });

    final response = await ApiClient.instance.dio.post(_base, data: form);
    return PortfolioModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  Future<void> removePortfolioItem(String id) async {
    await ApiClient.instance.dio.delete('$_base/$id');
  }

  List<PortfolioModel> _parse(Object? data) => [
        for (final item in (data as List? ?? const []))
          PortfolioModel.fromJson(item as Map<String, dynamic>),
      ];

  String _basename(String path) => path.split(RegExp(r'[/\\]')).last;

  /// The API only accepts JPG, PNG and WebP, so the part is labelled from
  /// the file's extension rather than sent as octet-stream.
  DioMediaType _mediaTypeFor(String path) {
    final name = _basename(path).toLowerCase();
    if (name.endsWith('.png')) return DioMediaType('image', 'png');
    if (name.endsWith('.webp')) return DioMediaType('image', 'webp');
    return DioMediaType('image', 'jpeg');
  }
}
