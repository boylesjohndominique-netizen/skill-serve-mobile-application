import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/features/booking/models/booking_model.dart';
import 'package:skillserve_mobile/features/booking/views/refund_section.dart';
import 'package:skillserve_mobile/features/identity/models/identity_verification_model.dart';

Map<String, dynamic> _refund([Map<String, dynamic> overrides = const {}]) => {
      'amount': '500.00',
      'status': 'due',
      'is_overdue': false,
      'due_by': '2026-10-17T09:00:00+08:00',
      ...overrides,
    };

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

void main() {
  test('a cancelled booking carries what the provider owes back', () {
    final booking = BookingModel.fromJson({
      'id': 9,
      'status': 'cancelled',
      'payment_status': 'partially_paid',
      'total_price': '1500.00',
      'amount_paid': '500.00',
      'refund': _refund({'status': 'sent', 'reference': '5001', 'proof_url': 'https://x/refund/proof'}),
    });

    expect(booking.refund?.amount, 500);
    expect(booking.refund?.isSent, isTrue);
    expect(booking.refund?.reference, '5001');
    expect(BookingModel.fromJson({'id': 1, 'status': 'cancelled'}).refund, isNull);
  });

  test('an unreturned refund is a reason the provider is blocked', () {
    final eligibility = TransactionEligibility.fromJson({'eligible': false, 'reason': 'refund_overdue', 'refunds_overdue': 1});
    expect(eligibility.blockedByRefund, isTrue);
    expect(eligibility.refundsOverdue, 1);
  });

  testWidgets('the provider is asked to return it, and an overdue one says they are blocked', (tester) async {
    await tester.pumpWidget(_host(RefundSection(
      refund: BookingRefund.fromJson(_refund()),
      isProviderView: true,
      isDark: false,
      onMarkSent: () {},
    )));
    expect(find.text("I've returned it — upload proof"), findsOneWidget);

    await tester.pumpWidget(_host(RefundSection(
      refund: BookingRefund.fromJson(_refund({'is_overdue': true})),
      isProviderView: true,
      isDark: false,
      onMarkSent: () {},
    )));
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.textContaining('cannot take new bookings'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('the customer confirms or reports a returned payment', (tester) async {
    var confirmed = false;
    await tester.pumpWidget(_host(RefundSection(
      refund: BookingRefund.fromJson(_refund({'status': 'sent'})),
      isProviderView: false,
      isDark: false,
      onConfirm: () => confirmed = true,
      onNotReceived: () {},
    )));

    expect(find.text('Not received'), findsOneWidget);
    await tester.tap(find.text('I received it'));
    expect(confirmed, isTrue);

    // Nothing to answer before the provider returns it.
    await tester.pumpWidget(_host(RefundSection(
      refund: BookingRefund.fromJson(_refund()),
      isProviderView: false,
      isDark: false,
    )));
    expect(find.text('I received it'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
  });
}
