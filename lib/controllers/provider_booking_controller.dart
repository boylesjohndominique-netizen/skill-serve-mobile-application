import 'package:flutter/foundation.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

/// Drives the provider's Booking Requests / Active / Completed job screens.
class ProviderBookingController extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<BookingModel> bookings = [];
  bool isLoading = false;

  Future<void> loadProviderBookings() async {
    isLoading = true;
    notifyListeners();
    bookings = await _bookingService.getProviderBookings();
    isLoading = false;
    notifyListeners();
  }

  List<BookingModel> get requests => bookings.where((b) => b.status == BookingStatus.pending).toList();
  List<BookingModel> get active =>
      bookings.where((b) => b.status == BookingStatus.confirmed || b.status == BookingStatus.inProgress).toList();
  List<BookingModel> get completed => bookings.where((b) => b.status == BookingStatus.completed).toList();

  Future<void> accept(String id) async {
    await _bookingService.acceptBooking(id);
    await loadProviderBookings();
  }

  Future<void> complete(String id) async {
    await _bookingService.completeBooking(id);
    await loadProviderBookings();
  }
}
