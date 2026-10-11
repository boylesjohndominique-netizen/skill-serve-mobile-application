import 'package:dio/dio.dart';

import '../../../core/services/api_client.dart';
import '../../../core/utils/image_upload.dart';
import '../models/commission_model.dart';

/// What the provider owes SkillServe, what a price would earn them, and
/// paying it (see api-docs/modules/provider-commissions.md and
/// provider-services.md):
/// - GET  /api/client/v1/provider/commissions
/// - GET  /api/client/v1/provider/commission-preview?amount=
/// - POST /api/client/v1/provider/commission-remittances
///
/// The app never takes the money: the provider sends it to SkillServe's GCash
/// outside the app, then submits the GCash reference number here for an
/// administrator to confirm.
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

  /// Submit a GCash payment covering everything owed now. [proofPath] is an
  /// optional receipt screenshot.
  Future<CommissionRemittance> submitRemittance({
    required String reference,
    required String amountSent,
    String? proofPath,
  }) async {
    final form = FormData.fromMap({
      'reference': reference,
      'amount_sent': amountSent,
      if (proofPath != null) 'proof': await imageMultipart(proofPath),
    });

    final response = await ApiClient.instance.dio.post(
      '/client/v1/provider/commission-remittances',
      data: form,
    );
    return CommissionRemittance.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
