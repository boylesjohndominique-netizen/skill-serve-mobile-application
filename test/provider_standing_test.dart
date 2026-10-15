import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/features/booking/models/booking_model.dart';
import 'package:skillserve_mobile/features/messaging/models/message_model.dart';

/// A customer learns when the provider they booked or messaged was suspended,
/// banned or deleted by an administrator.
void main() {
  Map<String, dynamic> booking(Map<String, dynamic> provider) => {
        'id': 7,
        'booking_number': 'BK-1',
        'status': 'confirmed',
        'scheduled_date': '2026-10-20T09:00:00+08:00',
        'service': {'id': 3, 'title': 'Pipe Repair'},
        'provider': {'id': 5, 'business_name': 'Standing Plumbing', ...provider},
      };

  test('a booking carries the provider standing and its notice', () {
    final suspended = BookingModel.fromJson(booking({
      'account_status': 'suspended',
      'account_notice': 'This provider has been suspended by SkillServe, so they cannot work on this booking.',
    }));
    expect(suspended.isProviderUnavailable, isTrue);
    expect(suspended.providerUnavailableTitle, 'Your provider was suspended');
    expect(suspended.providerUnavailableLabel, 'Provider suspended');
    expect(suspended.providerAccountNotice, contains('suspended by SkillServe'));

    final deleted = BookingModel.fromJson(booking({'account_status': 'deleted', 'account_notice': "This provider's account was deleted."}));
    expect(deleted.providerUnavailableTitle, "Your provider's account was deleted");
    expect(deleted.providerUnavailableLabel, 'Provider account deleted');
  });

  test('older payloads and active providers show nothing', () {
    expect(BookingModel.fromJson(booking({})).isProviderUnavailable, isFalse);
    expect(BookingModel.fromJson(booking({'account_status': 'active', 'account_notice': null})).isProviderUnavailable, isFalse);
  });

  test('a conversation carries the provider standing', () {
    final conversation = ConversationModel.fromJson({
      'kind': 'inquiry',
      'inquiry_id': 4,
      'counterpart': {
        'id': 9,
        'provider_id': 5,
        'name': 'Standing Plumbing',
        'account_status': 'banned',
        'account_notice': 'This provider has been banned from SkillServe.',
      },
    });
    expect(conversation.isProviderUnavailable, isTrue);
    expect(conversation.providerAccountNotice, 'This provider has been banned from SkillServe.');
    expect(conversation.copyWith(unreadCount: 0).isProviderUnavailable, isTrue);
  });
}
