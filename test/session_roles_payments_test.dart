import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillserve_mobile/core/services/token_storage.dart';
import 'package:skillserve_mobile/features/auth/controllers/auth_controller.dart';
import 'package:skillserve_mobile/features/auth/models/user_model.dart';
import 'package:skillserve_mobile/features/booking/models/booking_model.dart';
import 'package:skillserve_mobile/features/payments/models/payment_model.dart';
import 'package:skillserve_mobile/features/reports/models/report_model.dart';
import 'package:skillserve_mobile/routes/app_router.dart';

UserModel _user(UserRole role) => UserModel(
      id: '7',
      role: role,
      firstName: 'Maria',
      lastName: 'Santos',
      email: 'maria@skillserve.test',
      createdAt: DateTime(2026, 9, 1),
    );

BookingModel _booking({
  String status = 'completed',
  String paymentStatus = 'unpaid',
  double amount = 1500,
  double fee = 150,
}) =>
    BookingModel.fromJson({
      'id': 42,
      'booking_number': 'BK-ABC123',
      'status': status,
      'payment_status': paymentStatus,
      'total_price': '$amount',
      'platform_fee': '$fee',
      'payment_method': 'gcash',
      'scheduled_date': '2026-10-01T09:00:00+08:00',
      'created_at': '2026-09-24T08:00:00+08:00',
      'service': {'id': 7, 'title': 'Aircon Cleaning'},
      'provider': {'id': 3, 'business_name': 'Juan Aircon Services'},
    });

void main() {
  group('secure token storage', () {
    test('tokens an older build left in SharedPreferences move to secure storage', () async {
      SharedPreferences.setMockInitialValues({
        TokenStorage.accessTokenKey: 'access',
        TokenStorage.refreshTokenKey: 'refresh',
      });

      expect(await TokenStorage.readRefreshToken(), 'refresh');
      expect(await TokenStorage.readAccessToken(), 'access');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(TokenStorage.accessTokenKey), isNull);
      expect(prefs.getString(TokenStorage.refreshTokenKey), isNull);
      expect(await const FlutterSecureStorage().read(key: TokenStorage.refreshTokenKey), 'refresh');
    });

    test('new tokens are written only to secure storage and cleared on sign-out', () async {
      SharedPreferences.setMockInitialValues({});

      await TokenStorage.save(accessToken: 'a2', refreshToken: 'r2');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
      expect(await TokenStorage.readAccessToken(), 'a2');

      await TokenStorage.clear();
      expect(await TokenStorage.readAccessToken(), isNull);
      expect(await TokenStorage.readRefreshToken(), isNull);
    });

    test('a newer secure token is not overwritten by a stale legacy copy', () async {
      SharedPreferences.setMockInitialValues({TokenStorage.refreshTokenKey: 'stale'});
      FlutterSecureStorage.setMockInitialValues({TokenStorage.refreshTokenKey: 'current'});

      expect(await TokenStorage.readRefreshToken(), 'current');
      expect((await SharedPreferences.getInstance()).getString(TokenStorage.refreshTokenKey), isNull);
    });
  });

  group('staying signed in', () {
    test('a saved session is restored at launch without waiting on the network', () async {
      SharedPreferences.setMockInitialValues({
        TokenStorage.accessTokenKey: 'access',
        TokenStorage.refreshTokenKey: 'refresh',
        'skillserve.session.user': jsonEncode(_user(UserRole.client).toJson()),
      });

      final auth = AuthController();
      await auth.initialize();
      await auth.ready;

      expect(auth.status, AuthStatus.authenticated);
      expect(auth.isClient, isTrue);
      expect(auth.currentUser?.firstName, 'Maria');
      expect(auth.sessionExpired, isFalse);
    });

    test('a provider comes back as a provider', () async {
      SharedPreferences.setMockInitialValues({
        TokenStorage.accessTokenKey: 'access',
        TokenStorage.refreshTokenKey: 'refresh',
        'skillserve.session.user': jsonEncode(_user(UserRole.provider).toJson()),
      });

      final auth = AuthController();
      await auth.initialize();

      expect(auth.isProvider, isTrue);
    });

    test('an expired access token alone does not sign anyone out at launch', () async {
      // Only the refresh token is left — the access token expired and was
      // never replaced. The session is still valid.
      SharedPreferences.setMockInitialValues({
        TokenStorage.refreshTokenKey: 'refresh',
        'skillserve.session.user': jsonEncode(_user(UserRole.client).toJson()),
      });

      final auth = AuthController();
      await auth.initialize();

      expect(auth.status, AuthStatus.authenticated);
    });

    test('with no saved session the app starts signed out', () async {
      SharedPreferences.setMockInitialValues({});

      final auth = AuthController();
      await auth.initialize();
      await auth.ready;

      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.currentUser, isNull);
    });

    test('the old eight-hour expiry is cleared and never enforced', () async {
      SharedPreferences.setMockInitialValues({
        TokenStorage.accessTokenKey: 'access',
        'skillserve.session.user': jsonEncode(_user(UserRole.client).toJson()),
        // Written by earlier builds, long in the past.
        'skillserve.session.expiresAt': DateTime(2020).millisecondsSinceEpoch,
      });

      final auth = AuthController();
      await auth.initialize();

      expect(auth.status, AuthStatus.authenticated);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('skillserve.session.expiresAt'), isFalse);
    });
  });

  group('separate customer and provider apps', () {
    String? asClient(String path) => redirectFor(path: path, isClient: true, isProvider: false);
    String? asProvider(String path) => redirectFor(path: path, isClient: false, isProvider: true);
    String? asGuest(String path) => redirectFor(path: path, isClient: false, isProvider: false);

    test('a provider cannot open customer screens or shop the marketplace', () {
      for (final path in [
        '/client',
        '/booking-form/3',
        '/booking-history',
        '/reschedule-booking/42',
        '/favorites',
        '/payments',
        '/payment-details/42',
        '/write-review/42',
        '/my-reviews',
        '/browse',
        '/service-details/7',
        '/provider-profile/3',
      ]) {
        expect(asProvider(path), '/provider', reason: path);
      }
    });

    test('a customer cannot open provider screens', () {
      for (final path in [
        '/provider',
        '/booking-requests',
        '/active-jobs',
        '/my-services',
        '/add-service',
        '/edit-service/7',
        '/availability',
        '/earnings',
        '/portfolio',
        '/verification-status',
        '/statistics',
      ]) {
        expect(asClient(path), '/client', reason: path);
      }
    });

    test('shared screens are open to both roles', () {
      for (final path in [
        '/notifications',
        '/chat-conversation/42',
        '/booking-details/42',
        '/file-report',
        '/my-reports',
        '/support/tickets',
        '/support/tickets/3',
        '/edit-profile',
        '/account-deletion',
        '/help-center',
      ]) {
        expect(asClient(path), isNull, reason: 'customer $path');
        expect(asProvider(path), isNull, reason: 'provider $path');
      }
    });

    test('a provider can still see their own public profile and reviews', () {
      // Prefix matching would have treated /provider-preview as a provider
      // screen; it is the read-only public view.
      expect(asProvider('/provider-preview/3'), isNull);
      expect(asProvider('/reviews/3'), isNull);
      expect(asClient('/provider-preview/3'), isNull);
    });

    test('a signed-in user skips the sign-in screens', () {
      for (final path in ['/login', '/register', '/welcome', '/onboarding', '/']) {
        expect(asClient(path), '/client', reason: path);
        expect(asProvider(path), '/provider', reason: path);
      }
      expect(asClient('/splash'), isNull);
    });

    test('a guest is sent to login for anything that needs an account', () {
      expect(asGuest('/client'), '/login');
      expect(asGuest('/earnings'), '/login');
      expect(asGuest('/notifications'), '/login');
      // The public marketplace and the guest preview stay open.
      expect(asGuest('/browse'), isNull);
      expect(asGuest('/provider-preview/3'), isNull);
      expect(asGuest('/help-center'), isNull);
    });
  });

  group('payments come from bookings', () {
    test('an unpaid job still going ahead is owed', () {
      final payment = PaymentModel.fromBooking(_booking(status: 'confirmed'));

      expect(payment.status, PaymentStatus.unpaid);
      expect(payment.statusLabel, 'Unpaid');
      expect(payment.method, 'GCash');
      expect(payment.amount, 1500);
      expect(payment.bookingId, '42');
    });

    test('a cancelled, unpaid booking owes nothing', () {
      expect(PaymentModel.fromBooking(_booking(status: 'cancelled')).status, PaymentStatus.notDue);
    });

    test('paid and refunded come straight from the booking', () {
      expect(PaymentModel.fromBooking(_booking(paymentStatus: 'paid')).status, PaymentStatus.paid);
      expect(PaymentModel.fromBooking(_booking(paymentStatus: 'refunded')).status, PaymentStatus.refunded);
      expect(
        PaymentModel.fromBooking(_booking(paymentStatus: 'partially_refunded')).status,
        PaymentStatus.partiallyRefunded,
      );
    });

    test('a provider earns the price less the platform fee', () {
      final job = _booking(amount: 1500, fee: 150);

      expect(job.platformFee, 150);
      expect(job.providerEarnings, 1350);
      expect(job.isPaid, isFalse);
    });
  });

  group('reports about reviews and messages', () {
    test('a review report names the author and shows the text', () {
      final report = ReportModel.fromJson({
        'id': 9,
        'subject_type': 'review',
        'reason': 'inappropriate_content',
        'description': 'Review: abusive',
        'status': 'pending',
        'reported': {'name': 'Ana Cruz', 'excerpt': 'Terrible!!!'},
        'created_at': '2026-10-01T09:00:00+08:00',
      });

      expect(report.subjectType, 'review');
      expect(report.subjectLabel, 'Review by Ana Cruz');
      expect(report.excerpt, 'Terrible!!!');
      expect(report.reasonLabel, 'Offensive or inappropriate content');
    });

    test('a message report reads as a message', () {
      final report = ReportModel.fromJson({
        'id': 10,
        'subject_type': 'message',
        'reason': 'harassment',
        'description': 'Message: threats',
        'status': 'pending',
        'reported': {'name': 'Juan', 'excerpt': 'Pay me outside the app'},
        'created_at': '2026-10-01T09:00:00+08:00',
      });

      expect(report.subjectLabel, 'Message from Juan');
    });

    test('the two reason lists only offer API values', () {
      for (final reason in [...ReportReason.forPeople, ...ReportReason.forContent]) {
        expect(ReportReason.fromValue(reason.value), reason);
      }
    });

    test('dispute evidence parses, and the files are never addressed', () {
      final dispute = DisputeModel.fromJson({
        'booking_id': 42,
        'dispute_status': 'pending',
        'can_add_evidence': true,
        'evidence': [
          {
            'id': 'a1',
            'label': 'Water still leaking',
            'uploaded_by_role': 'customer',
            'is_mine': true,
            'uploaded_at': '2026-10-02T10:00:00+08:00',
          },
          {'id': 'b2', 'label': 'access.png', 'uploaded_by_role': 'provider', 'is_mine': false},
        ],
      });

      expect(dispute.canAddEvidence, isTrue);
      expect(dispute.evidence, hasLength(2));
      expect(dispute.evidence.first.label, 'Water still leaking');
      expect(dispute.evidence.first.isMine, isTrue);
      expect(dispute.evidence.last.uploadedByRole, 'provider');
    });
  });
}
