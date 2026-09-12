import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

/// Drives the client's Booking History / Booking Details screens.
class BookingController extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<BookingModel> bookings = [];
  bool isLoading = false;

  Future<void> loadClientBookings() async {
    isLoading = true;
    notifyListeners();
    try {
      bookings = await _bookingService.getClientBookings();
    } catch (_) {
      bookings = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> cancel(String bookingId) async {
    try {
      await _bookingService.cancelBooking(bookingId);
      await loadClientBookings();
    } catch (_) {}
  }
}
