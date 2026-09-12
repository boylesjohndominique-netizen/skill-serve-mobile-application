import '../models/notification_model.dart';
import '../../../core/services/api_client.dart';

/// Service for the notifications feed — live API only.
///
/// Endpoints:
/// - GET /api/client/v1/notifications
/// - PATCH /api/client/v1/notifications/{notification}/read
/// - POST /api/client/v1/notifications/read-all
/// - GET /api/client/v1/notifications/unread-count
class NotificationService {
  // GET /api/client/v1/notifications
  Future<List<NotificationModel>> getNotifications() async {
    final response =
        await ApiClient.instance.dio.get('/client/v1/notifications');
    final data = response.data['data'];
    final items = data is List
        ? data
        : data is Map<String, dynamic>
            ? data['data'] as List? ?? []
            : [];
    return items
        .map((item) =>
            NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // PATCH /api/client/v1/notifications/{notification}/read
  Future<void> markAsRead(String id) async {
    await ApiClient.instance.dio.patch('/client/v1/notifications/$id/read');
  }

  // POST /api/client/v1/notifications/read-all
  Future<void> markAllAsRead() async {
    await ApiClient.instance.dio.post('/client/v1/notifications/read-all');
  }

  // GET /api/client/v1/notifications/unread-count
  Future<int> unreadCount() async {
    final response = await ApiClient.instance.dio
        .get('/client/v1/notifications/unread-count');
    return (response.data['data']?['count'] as num?)?.toInt() ?? 0;
  }
}
