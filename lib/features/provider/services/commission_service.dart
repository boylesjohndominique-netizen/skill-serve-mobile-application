import '../../../core/services/api_client.dart';
import '../models/commission_model.dart';

/// What the provider owes SkillServe, and what a price would earn them
/// (see api-docs/modules/provider-commissions.md and provider-services.md):
/// - GET /api/client/v1/provider/commissions
/// - GET /api/client/v1/provider/commission-preview?amount=
///
/// Read-only by design. SkillServe is never in the payment path, so there is
/// nothing for the app to charge: the provider remits what they owe outside
/// the platform and an administrator records it against the ledger.
class CommissionService {
  static const _path = '/client/v1/provider/commissions';

  Future<CommissionSummary> getSummary() async {
    final response = await ApiClient.instance.dio.get(_path);
    return CommissionSummary.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// SkillServe's share of [amount] and what the provider keeps, under the
  /// rates in force now.
  Future<CommissionSplit> preview(double amount) async {
    final response = await ApiClient.instance.dio.get(
      '/client/v1/provider/commission-preview',
      queryParameters: {'amount': amount},
    );
    return CommissionSplit.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
