/// Mirrors the `payments` table. Payment methods match the platform list:
/// GCash · Maya · Cash on hand · Card.
enum PaymentStatus { paid, pending, failed, refunded }

class PaymentModel {
  final String id; // PAY-8001
  final String bookingId;
  final String clientName;
  final String providerName;
  final String method; // GCash | Maya | Cash on hand | Card
  final double amount;
  final PaymentStatus status;
  final String reference; // TXN-123456 or COD-123456
  final DateTime paidAt;

  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.clientName,
    required this.providerName,
    required this.method,
    required this.amount,
    required this.status,
    required this.reference,
    required this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        id: json['payment_id'].toString(),
        bookingId: json['booking_id'].toString(),
        clientName: json['client_name'] as String? ?? '',
        providerName: json['provider_name'] as String? ?? '',
        method: json['method'] as String? ?? 'Cash on hand',
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        status: PaymentStatus.values.byName(json['status'] as String? ?? 'pending'),
        reference: json['reference'] as String? ?? 'TXN-000000',
        paidAt: DateTime.tryParse(json['paid_at'] as String? ?? '') ?? DateTime.now(),
      );
}
