import '../data/mock/mock_data.dart';
import '../models/payment_model.dart';
import 'api_client.dart';

/// Placeholder service for payments & receipts.
class PaymentService {
  // GET /payments (own)
  Future<List<PaymentModel>> getPayments() async {
    await simulateNetworkDelay();
    return MockData.payments;
  }

  // GET /payments/:id
  Future<PaymentModel> getPaymentById(String id) async {
    await simulateNetworkDelay(ms: 300);
    return MockData.payments.firstWhere((p) => p.id == id, orElse: () => MockData.payments.first);
  }
}
