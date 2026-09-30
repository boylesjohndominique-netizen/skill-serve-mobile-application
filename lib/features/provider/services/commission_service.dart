import '../../../core/services/api_client.dart';
import '../models/commission_model.dart';

/// What the provider owes SkillServe
/// (see api-docs/modules/provider-commissions.md):
/// - GET /api/client/v1/provider/commissions
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
}
