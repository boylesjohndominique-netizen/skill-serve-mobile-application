import 'package:flutter/foundation.dart';
import '../../../core/utils/api_error.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

/// Drives the customer's Payments history and a single payment's details.
class PaymentController extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  List<PaymentModel> payments = [];
  bool isLoading = false;
  String? errorMessage;

  /// What is still owed across every booking going ahead or done.
  double get outstanding => payments
      .where((p) => p.status == PaymentStatus.unpaid)
      .fold(0, (sum, p) => sum + p.amount);

  double get settled => payments
      .where((p) => p.status == PaymentStatus.paid)
      .fold(0, (sum, p) => sum + p.amount);

  Future<void> loadPayments() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      payments = await _paymentService.getPayments();
    } catch (e) {
      payments = [];
      errorMessage = apiErrorMessage(e, 'Unable to load your payments.');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<PaymentModel?> loadPayment(String bookingId) async {
    try {
      return await _paymentService.getPaymentForBooking(bookingId);
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to load this payment.');
      notifyListeners();
      return null;
    }
  }
}
