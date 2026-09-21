import '../../../core/services/api_client.dart';
import '../models/platform_info.dart';

/// `GET /api/client/v1/platform` — public, and still answered during
/// maintenance mode (api-docs/modules/client-platform.md).
class PlatformService {
  Future<PlatformInfo> get() async {
    final response = await ApiClient.instance.dio.get('/client/v1/platform');
    return PlatformInfo.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
