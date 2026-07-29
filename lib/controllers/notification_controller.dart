import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> notifications = [];
  bool isLoading = false;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    notifications = await _service.getNotifications();
    isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    await _service.markAsRead(id);
    notifications = [
      for (final n in notifications)
        if (n.id == id)
          NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            createdAt: n.createdAt,
            isRead: true,
          )
        else
          n,
    ];
    notifyListeners();
  }
}
