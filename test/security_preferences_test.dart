import 'package:flutter_test/flutter_test.dart';
import 'package:skilllink_mobile/features/settings/controllers/preferences_controller.dart';

void main() {
  test('preferences expose safe defaults for all supported settings', () {
    final controller = PreferencesController();

    expect(controller.bookingNotifications, isTrue);
    expect(controller.serviceNotifications, isTrue);
    expect(controller.messageNotifications, isTrue);
    expect(controller.announcementNotifications, isTrue);
    expect(controller.privateProfile, isFalse);
    expect(controller.activityPersonalization, isTrue);
    expect(controller.reduceMotion, isFalse);
  });
}
