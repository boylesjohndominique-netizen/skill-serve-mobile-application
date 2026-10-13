import '../models/notification_model.dart';
import '../../../core/services/api_client.dart';

/// Service for the notifications feed — live API only.
///
/// Endpoints:
/// - GET /api/client/v1/notifications
/// - PATCH /api/client/v1/notifications/{notification}/read
/// - POST /api/client/v1/notifications/read-all
/// - GET /api/client/v1/notifications/unread-count
/// - POST /api/client/v1/notifications/archive | unarchive | delete  ({ids})
class NotificationService {
  /// GET /api/client/v1/notifications — the feed, or the archive when
  /// [archived].
  Future<List<NotificationModel>> getNotifications({bool archived = false}) async {
    final response = await ApiClient.instance.dio.get(
      '/client/v1/notifications',
      queryParameters: {'per_page': 50, if (archived) 'archived': 1},
    );
    final data = response.data['data'];
    final items = data is List
        ? data
        : data is Map<String, dynamic>
            ? data['data'] as List? ?? []
            : [];
    return items.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>)).toList();
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
    final response = await ApiClient.instance.dio.get('/client/v1/notifications/unread-count');
    final data = response.data['data'];
    // The API returns {"unread_count": n}; older builds expected "count".
    return ((data?['unread_count'] ?? data?['count']) as num?)?.toInt() ?? 0;
  }

  /// Moves [ids] to the archive (they are marked read there).
  Future<void> archive(List<String> ids) =>
      ApiClient.instance.dio.post('/client/v1/notifications/archive', data: {'ids': ids});

  /// Brings archived [ids] back to the feed.
  Future<void> unarchive(List<String> ids) =>
      ApiClient.instance.dio.post('/client/v1/notifications/unarchive', data: {'ids': ids});

  /// Deletes [ids] for good.
  Future<void> delete(List<String> ids) =>
      ApiClient.instance.dio.post('/client/v1/notifications/delete', data: {'ids': ids});
}
