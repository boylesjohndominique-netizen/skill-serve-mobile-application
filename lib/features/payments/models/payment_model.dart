import '../../booking/models/booking_model.dart';

/// Where a booking's payment stands, as the customer should read it.
///
/// SkillServe does not process payments: the customer settles with the
/// provider directly, and the provider (or an administrator) records on the
/// booking that it was paid, and any refund.
/// There is no separate payments table and no transaction reference, so this
/// is a view over each booking — never a made-up receipt.
enum PaymentStatus {
  /// Settled — the provider or an administrator recorded the payment.
  paid,

  /// Owed to the provider for a job that is going ahead or has been done.
  unpaid,

  /// The booking was cancelled before anything was paid, so nothing is owed.
  notDue,
  refunded,
  partiallyRefunded,
}

class PaymentModel {
  /// The booking this payment belongs to — also how it is opened.
  final String bookingId;
  final String bookingNumber;
  final String serviceTitle;
  final String providerName;

  /// The method the customer chose at booking time, as a label.
  final String method;
  final String? methodCode;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final BookingStatus bookingStatus;

  /// When the job is (or was) scheduled — the date the payment relates to.
  final DateTime date;

  /// When the payment was recorded; null while unpaid.
  final DateTime? paidAt;
  final double refundedAmount;
  final String? refundReason;

  const PaymentModel({
    required this.bookingId,
    this.bookingNumber = '',
    this.serviceTitle = '',
    this.providerName = '',
    required this.method,
    this.methodCode,
    required this.amount,
    this.currency = 'PHP',
    required this.status,
    required this.bookingStatus,
    required this.date,
    this.paidAt,
    this.refundedAmount = 0,
    this.refundReason,
  });

  /// The status key the shared badge understands.
  String get statusKey => switch (status) {
        PaymentStatus.paid => 'paid',
        PaymentStatus.unpaid => 'pending',
        PaymentStatus.notDue => 'closed',
        PaymentStatus.refunded => 'refunded',
        PaymentStatus.partiallyRefunded => 'refunded',
      };

  String get statusLabel => switch (status) {
        PaymentStatus.paid => 'Paid',
        PaymentStatus.unpaid => 'Unpaid',
        PaymentStatus.notDue => 'Nothing due',
        PaymentStatus.refunded => 'Refunded',
        PaymentStatus.partiallyRefunded => 'Partly refunded',
      };

  factory PaymentModel.fromBooking(BookingModel booking) => PaymentModel(
        bookingId: booking.id,
        bookingNumber: booking.bookingNumber,
        serviceTitle: booking.serviceTitle,
        providerName: booking.providerName,
        method: booking.paymentMethod,
        methodCode: booking.paymentMethodCode,
        amount: booking.amount,
        currency: booking.currency,
        status: statusFor(booking),
        bookingStatus: booking.status,
        date: booking.bookingDate,
        paidAt: booking.paidAt,
        refundedAmount: booking.refundedAmount,
        refundReason: booking.refundReason,
      );

  static PaymentStatus statusFor(BookingModel booking) {
    switch (booking.paymentStatus) {
      case 'paid':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'partially_refunded':
        return PaymentStatus.partiallyRefunded;
    }
    // Unpaid: owed, unless the job was called off before any work.
    return booking.status == BookingStatus.cancelled
        ? PaymentStatus.notDue
        : PaymentStatus.unpaid;
  }
}
