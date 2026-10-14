import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/core/widgets/buttons/primary_button.dart';
import 'package:skillserve_mobile/features/booking/controllers/booking_controller.dart';
import 'package:skillserve_mobile/features/booking/models/booking_model.dart';
import 'package:skillserve_mobile/features/booking/views/payment_proof_section.dart';
import 'package:skillserve_mobile/features/payments/models/payment_model.dart';

Map<String, dynamic> _booking([Map<String, dynamic> overrides = const {}]) => {
      'id': 12,
      'booking_number': 'BK-PAY-1',
      'status': 'confirmed',
      'payment_status': 'unpaid',
      'payment_method': 'gcash',
      'total_price': '1500.00',
      'amount_paid': '0.00',
      'balance_due': '1500.00',
      'scheduled_date': '2026-10-20T09:00:00+08:00',
      'payment_proofs': [],
      ...overrides,
    };

void main() {
  group('GCash payment proofs on a booking', () {
    test('a downpayment leaves the rest to pay, and the proof is read', () {
      final booking = BookingModel.fromJson(_booking({
        'payment_status': 'partially_paid',
        'amount_paid': '500.00',
        'balance_due': '1000.00',
        'payment_proofs': [
          {'id': 3, 'amount': '500.00', 'reference': '1009', 'status': 'confirmed', 'image_url': 'https://x/3/image', 'created_at': '2026-10-14T09:00:00+08:00'},
        ],
      }));

      expect(booking.isOwing, isTrue);
      expect(booking.amountPaid, 500);
      expect(booking.balanceDue, 1000);
      expect(booking.paymentLabel, 'Partly paid');
      expect(booking.paymentProofs.single.isConfirmed, isTrue);
      expect(booking.canSendPaymentProof, isTrue);
      expect(PaymentModel.fromBooking(booking).status, PaymentStatus.partiallyPaid);
    });

    test('proof can be sent only for an accepted GCash booking with nothing waiting', () {
      expect(BookingModel.fromJson(_booking()).canSendPaymentProof, isTrue);
      expect(BookingModel.fromJson(_booking({'status': 'pending'})).canSendPaymentProof, isFalse);
      expect(BookingModel.fromJson(_booking({'payment_method': 'on_hand'})).canSendPaymentProof, isFalse);
      expect(BookingModel.fromJson(_booking({'payment_status': 'paid', 'balance_due': '0.00'})).canSendPaymentProof, isFalse);

      final waiting = BookingModel.fromJson(_booking({
        'payment_proofs': [
          {'id': 4, 'amount': '1500.00', 'status': 'pending'},
        ],
      }));
      expect(waiting.pendingProof?.id, '4');
      expect(waiting.canSendPaymentProof, isFalse);
    });

    test('an older payload without a balance owes the whole price while unpaid', () {
      final booking = BookingModel.fromJson(_booking()..remove('balance_due'));
      expect(booking.balanceDue, 1500);
    });
  });

  testWidgets('the send-proof sheet refuses more than is owed and needs a screenshot', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(onPressed: () => showSendPaymentProofSheet(context, balance: 1000), child: const Text('open')),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Starts at the full balance; nothing to complain about.
    expect(find.textContaining('still to pay'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, '1200');
    await tester.pump();
    expect(find.text('At most ₱1,000 is still to pay.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '400');
    await tester.pump();
    expect(find.textContaining('A downpayment'), findsOneWidget);

    // No screenshot yet: the button stays off.
    final send = tester.widget<PrimaryButton>(find.widgetWithText(PrimaryButton, 'Send to provider'));
    expect(send.onPressed, isNull);
  });

  test('a realtime change signals the booking, even when the reload fails', () async {
    final controller = BookingController();
    final before = controller.changeCount;

    await controller.onRealtimeChange('12');

    expect(controller.changedBookingId, '12');
    expect(controller.changeCount, before + 1);
  });
}
