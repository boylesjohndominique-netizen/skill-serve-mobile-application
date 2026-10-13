import 'package:dio/dio.dart';

import '../models/portfolio_model.dart';
import '../../../core/services/api_client.dart';
import '../../../core/utils/image_upload.dart';

/// A provider's portfolio: pieces of work with up to ten photos each.
///
/// Endpoints:
/// - GET    /api/client/v1/provider/portfolio                     (the signed-in provider's own)
/// - POST   /api/client/v1/provider/portfolio                     (multipart, `images[]`)
/// - PATCH  /api/client/v1/provider/portfolio/{item}              (title, description)
/// - POST   /api/client/v1/provider/portfolio/{item}/images       (multipart, `images[]`)
/// - DELETE /api/client/v1/provider/portfolio/{item}/images/{image}
/// - DELETE /api/client/v1/provider/portfolio/{item}
/// - GET    /api/client/v1/providers/{provider}                   (public: `portfolio` on the profile)
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
    final response = await ApiClient.instance.dio.get('/client/v1/providers/$providerId');
    final data = response.data['data'] as Map<String, dynamic>;
    return _parse(data['portfolio']);
  }

  /// A new piece of work; the first of [imagePaths] is the cover.
  Future<PortfolioModel> uploadPortfolioItem({
    required String title,
    required String description,
    required List<String> imagePaths,
  }) async {
    final form = FormData.fromMap({
      'title': title,
      if (description.isNotEmpty) 'description': description,
      'images[]': [for (final path in imagePaths) await imageMultipart(path)],
    });
    final response = await ApiClient.instance.dio.post(_base, data: form);
    return PortfolioModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PortfolioModel> updatePortfolioItem(String id, {required String title, required String description}) async {
    final response = await ApiClient.instance.dio.patch('$_base/$id', data: {
      'title': title,
      'description': description,
    });
    return PortfolioModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PortfolioModel> addPhotos(String id, List<String> imagePaths) async {
    final form = FormData.fromMap({
      'images[]': [for (final path in imagePaths) await imageMultipart(path)],
    });
    final response = await ApiClient.instance.dio.post('$_base/$id/images', data: form);
    return PortfolioModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PortfolioModel> removePhoto(String id, String photoId) async {
    final response = await ApiClient.instance.dio.delete('$_base/$id/images/$photoId');
    return PortfolioModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> removePortfolioItem(String id) async {
    await ApiClient.instance.dio.delete('$_base/$id');
  }

  List<PortfolioModel> _parse(Object? data) => [
        for (final item in (data as List? ?? const []))
          PortfolioModel.fromJson(item as Map<String, dynamic>),
      ];
}
