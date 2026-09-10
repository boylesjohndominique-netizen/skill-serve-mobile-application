import '../data/mock/mock_data.dart';
import '../models/notification_model.dart';
import '../core/config/app_config.dart';
import 'api_client.dart';

/// Placeholder service for the notifications feed.
class NotificationService {
  // API: GET /api/client/v1/notifications
  Future<List<NotificationModel>> getNotifications() async {
    if (!AppConfig.useMockData) {
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
    await simulateNetworkDelay(ms: 350);
    return MockData.notifications;
  }

  // API: PATCH /api/client/v1/notifications/{notification}/read
  Future<void> markAsRead(String id) async {
    if (!AppConfig.useMockData) {
      await ApiClient.instance.dio.patch('/client/v1/notifications/$id/read');
      return;
    }
    await simulateNetworkDelay(ms: 150);
  }

  // API: POST /api/client/v1/notifications/read-all
  Future<void> markAllAsRead() async {
    if (!AppConfig.useMockData) {
      await ApiClient.instance.dio.post('/client/v1/notifications/read-all');
      return;
    }
    await simulateNetworkDelay(ms: 150);
  }

  // API: GET /api/client/v1/notifications/unread-count
  Future<int> unreadCount() async {
    if (!AppConfig.useMockData) {
      final response = await ApiClient.instance.dio
          .get('/client/v1/notifications/unread-count');
      return (response.data['data']?['count'] as num?)?.toInt() ?? 0;
    }
    return MockData.notifications
        .where((notification) => !notification.isRead)
        .length;
  }
}
