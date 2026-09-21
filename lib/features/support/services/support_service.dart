import '../models/support_ticket_model.dart';
import '../../../core/services/api_client.dart';

/// Service for support tickets — live API only.
///
/// Endpoints (api-docs/modules/client-support.md):
/// - GET  /api/client/v1/support/tickets
/// - POST /api/client/v1/support/tickets
/// - GET  /api/client/v1/support/tickets/{ticket}
/// - POST /api/client/v1/support/tickets/{ticket}/replies
///
/// Open to customers and providers alike; each sees only their own tickets.
class SupportService {
  static const _base = '/client/v1/support/tickets';

  /// GET /api/client/v1/support/tickets — list rows carry no replies.
  Future<List<SupportTicketModel>> getTickets({TicketStatus? status}) async {
    final response = await ApiClient.instance.dio.get(_base, queryParameters: {
      'per_page': 100,
      if (status != null) 'status': SupportTicketModel.statusToApi(status),
    });
    return [
      for (final item in response.data['data'] as List? ?? const [])
        SupportTicketModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// GET /api/client/v1/support/tickets/{ticket} — the ticket and its thread.
  Future<SupportTicketModel> getTicket(String id) async {
    final response = await ApiClient.instance.dio.get('$_base/$id');
    return SupportTicketModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/client/v1/support/tickets
  Future<SupportTicketModel> createTicket({
    required String subject,
    required String description,
    required TicketCategory category,
  }) async {
    final response = await ApiClient.instance.dio.post(_base, data: {
      'subject': subject,
      'description': description,
      'category': category.value,
    });
    return SupportTicketModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// POST /api/client/v1/support/tickets/{ticket}/replies — returns the whole
  /// ticket, so the caller can replace its copy of the thread.
  Future<SupportTicketModel> reply(String id, String body) async {
    final response =
        await ApiClient.instance.dio.post('$_base/$id/replies', data: {'body': body});
    return SupportTicketModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
