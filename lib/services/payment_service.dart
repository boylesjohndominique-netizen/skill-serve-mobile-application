import '../models/payment_model.dart';

/// Service for payments & receipts.
///
/// No documented client endpoints for payments. These methods will
/// throw [UnsupportedError] until the backend documents client payment routes.
class PaymentService {
  // No documented client endpoint.
  Future<List<PaymentModel>> getPayments() async {
    throw UnsupportedError('Client payment endpoints are not documented.');
  }

  // No documented client endpoint.
  Future<PaymentModel> getPaymentById(String id) async {
    throw UnsupportedError('Client payment endpoints are not documented.');
  }
}
