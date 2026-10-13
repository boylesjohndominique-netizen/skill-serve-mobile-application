import '../../../core/services/api_client.dart';
import '../models/provider_statistics_model.dart';

/// GET /api/client/v1/provider/statistics — the signed-in provider's
/// performance, computed live by the API.
class StatisticsService {
  Future<ProviderStatistics> getStatistics({int months = 6}) async {
    final response = await ApiClient.instance.dio.get(
      '/client/v1/provider/statistics',
      queryParameters: {'months': months},
    );
    return ProviderStatistics.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
