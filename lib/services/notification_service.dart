import '../data/mock/mock_data.dart';
import '../models/notification_model.dart';
import 'api_client.dart';

/// Placeholder service for the notifications feed.
class NotificationService {
  // GET /notifications
  Future<List<NotificationModel>> getNotifications() async {
    await simulateNetworkDelay(ms: 350);
    return MockData.notifications;
  }

  // PATCH /notifications/:id/read
  Future<void> markAsRead(String id) async => simulateNetworkDelay(ms: 150);
}
