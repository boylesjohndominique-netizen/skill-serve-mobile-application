import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/core/models/account_restriction.dart';
import 'package:skillserve_mobile/features/auth/models/user_model.dart';

DioException _refusal(Map<String, dynamic> body, {int status = 403}) {
  final options = RequestOptions(path: '/client/v1/auth/login');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  group('AccountRestriction', () {
    test('reads a suspension with its reason from meta.account', () {
      final restriction = AccountRestriction.fromError(_refusal({
        'success': false,
        'message': 'Your account is suspended.',
        'meta': {'account': {'status': 'suspended', 'reason': 'Repeated no-shows.', 'since': '2026-09-20T02:00:00+00:00', 'until': null}},
      }))!;

      expect(restriction.status, 'suspended');
      expect(restriction.reason, 'Repeated no-shows.');
      expect(restriction.title, 'Your account is suspended');
    });

    test('tells a temporary ban from a permanent one', () {
      final temporary = AccountRestriction.fromJson({'status': 'banned', 'until': '2026-10-01T00:00:00+00:00'});
      final permanent = AccountRestriction.fromJson({'status': 'banned', 'until': null});

      expect(temporary.isPermanent, isFalse);
      expect(temporary.explanation, startsWith('You can sign in again after'));
      expect(permanent.isPermanent, isTrue);
      expect(permanent.explanation, 'This ban is permanent.');
    });

    test('other failures are not restrictions', () {
      expect(AccountRestriction.fromError(_refusal({'message': 'Invalid email or password.'}, status: 401)), isNull);
      expect(AccountRestriction.fromError(_refusal({'message': 'Please verify your email.'})), isNull);
      expect(AccountRestriction.fromError(Exception('offline')), isNull);
    });
  });

  test('a provider suspension from /auth/me survives the cached session', () {
    final user = UserModel.fromJson({
      'id': 5,
      'role_id': 3,
      'first_name': 'Juan',
      'last_name': 'Cruz',
      'email': 'juan@skillserve.test',
      'status': 'active',
      'provider': {'verification_status': 'verified', 'suspended': true, 'suspension_reason': 'Under review.'},
    });
    final restored = UserModel.fromJson(user.toJson());

    expect(restored.providerSuspended, isTrue);
    expect(restored.providerSuspensionReason, 'Under review.');
    expect(restored.providerVerificationStatus, 'verified');
  });
}
