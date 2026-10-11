import '../../../core/services/api_client.dart';
import '../models/commission_model.dart';

/// What the provider owes SkillServe, what a price would earn them, and
/// paying it (see api-docs/modules/provider-commissions.md and
/// provider-services.md):
/// - GET  /api/client/v1/provider/commissions
/// - GET  /api/client/v1/provider/commission-preview?amount=
/// - POST /api/client/v1/provider/commission-remittances/qr
/// - GET  /api/client/v1/provider/commission-remittances/{id}
///
/// The commission is paid only by a PayMongo QR Ph code for the exact amount,
/// confirmed by PayMongo — the app never takes or reports the money itself.
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

  /// A PayMongo QR Ph code for everything owed now — or the one already open.
  /// The amount is the server's; nothing about it is sent from here.
  Future<CommissionRemittance> startQrPayment() async {
    final response = await ApiClient.instance.dio.post('/client/v1/provider/commission-remittances/qr');
    return CommissionRemittance.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// One payment, to follow a QR code until PayMongo confirms it.
  Future<CommissionRemittance> getRemittance(int id) async {
    final response = await ApiClient.instance.dio.get('/client/v1/provider/commission-remittances/$id');
    return CommissionRemittance.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
