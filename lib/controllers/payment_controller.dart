import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

/// Drives the client's Payments history / receipt screens.
class PaymentController extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  List<PaymentModel> payments = [];
  bool isLoading = false;

  Future<void> loadPayments() async {
    isLoading = true;
    notifyListeners();
    payments = await _paymentService.getPayments();
    isLoading = false;
    notifyListeners();
  }
}
