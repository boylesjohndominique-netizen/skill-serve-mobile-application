import 'package:flutter_test/flutter_test.dart';
import 'package:skilllink_mobile/features/notifications/models/notification_model.dart';
import 'package:skilllink_mobile/features/provider/models/provider_service_model.dart';

void main() {
  test('provider service parses the API shape including moderation state', () {
    final service = ProviderServiceModel.fromJson({
      'id': 12,
      'title': 'Aircon Cleaning',
      'description': null,
      'price': '1500.00',
      'price_type': 'hourly',
      'duration': '2 hours',
      'location': 'Quezon City',
      'category_id': 3,
      'subcategory_id': null,
      'category': {'id': 3, 'name': 'Appliance Repair'},
      'status': 'draft',
      'approval_status': 'rejected',
      'rejection_reason': 'Add photos',
      'is_hidden': false,
      'is_featured': false,
    });

    expect(service.id, '12');
    expect(service.price, 1500);
    expect(service.priceType, 'hourly');
    expect(service.categoryId, '3');
    expect(service.categoryName, 'Appliance Repair');
    expect(service.subcategoryId, isNull);
    expect(service.isRejected, isTrue);
    expect(service.rejectionReason, 'Add photos');
    expect(service.isLive, isFalse);
  });

  test('only approved, published, visible services are live', () {
    ProviderServiceModel build({String approval = 'approved', String status = 'published', bool hidden = false}) =>
        ProviderServiceModel.fromJson({
          'id': 1,
          'title': 'x',
          'price': 1,
          'category_id': 1,
          'status': status,
          'approval_status': approval,
          'is_hidden': hidden,
        });

    expect(build().isLive, isTrue);
    expect(build(approval: 'pending', status: 'draft').isLive, isFalse);
    expect(build(hidden: true).isLive, isFalse);
  });

  test('categories include their subcategories', () {
    final category = ServiceCategoryOption.fromJson({
      'id': 3,
      'name': 'Appliance Repair',
      'subcategories': [
        {'id': 7, 'category_id': 3, 'name': 'Aircon'},
      ],
    });

    expect(category.id, '3');
    expect(category.subcategories.single.name, 'Aircon');
  });

  test('notifications parse the client API shape and service moderation type', () {
    final notification = NotificationModel.fromJson({
      'id': '9f1c2d3e-0000-4000-8000-000000000001',
      'type': 'service_moderation',
      'title': 'Service approved',
      'message': 'Your service “Aircon Cleaning” was approved.',
      'read_at': null,
      'created_at': '2026-09-17T09:00:00+00:00',
    });

    expect(notification.id, '9f1c2d3e-0000-4000-8000-000000000001');
    expect(notification.type, NotificationType.service);
    expect(notification.isRead, isFalse);
    expect(NotificationModel.typeFromApi('support_ticket_response'), NotificationType.system);
    expect(NotificationModel.typeFromApi('booking'), NotificationType.booking);
  });
}
