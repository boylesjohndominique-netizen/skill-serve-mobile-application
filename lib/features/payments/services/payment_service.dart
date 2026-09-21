import '../../booking/services/booking_service.dart';
import '../models/payment_model.dart';

/// Payment history — live API only, read from the customer's bookings.
///
/// Every booking carries its own payment record (`payment_method`,
/// `payment_status`, `total_price`), and that is all the platform holds:
/// payments are settled with the provider, not processed in the app. So this
/// reads the bookings rather than inventing a separate payments source.
///
/// Endpoints:
/// - GET /api/client/v1/bookings
/// - GET /api/client/v1/bookings/{booking}
class PaymentService {
  final BookingService _bookings = BookingService();

  /// Newest first.
  Future<List<PaymentModel>> getPayments() async {
    final bookings = await _bookings.getClientBookings();
    return [for (final booking in bookings) PaymentModel.fromBooking(booking)]
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// The payment for one booking.
  Future<PaymentModel> getPaymentForBooking(String bookingId) async {
    return PaymentModel.fromBooking(await _bookings.getClientBooking(bookingId));
  }
}
