import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/features/settings/models/platform_info.dart';

void main() {
  test('platform info carries the admin policies, rules and maintenance flag', () {
    final platform = PlatformInfo.fromJson({
      'platform_name': 'SkillServe',
      'support_email': 'support@skillserve.ph',
      'maintenance_mode': true,
      'provider_registration_enabled': false,
      'booking': {'booking_enabled': false, 'cancellation_window_hours': 12},
      'policies': {'terms_of_service': 'Terms…', 'privacy_policy': '', 'community_guidelines': 'Be kind.'},
    });

    expect(platform.maintenanceMode, isTrue);
    expect(platform.providerRegistrationEnabled, isFalse);
    expect(platform.bookingEnabled, isFalse);
    expect(platform.cancellationWindowHours, 12);
    expect(platform.policy('terms_of_service'), 'Terms…');
    expect(platform.policy('privacy_policy'), isEmpty);
    expect(platform.policy('community_guidelines'), 'Be kind.');
  });

  test('a blank platform name falls back to SkillServe', () {
    expect(PlatformInfo.fromJson({'platform_name': ' '}).name, 'SkillServe');
  });
}
