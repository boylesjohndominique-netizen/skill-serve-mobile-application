import 'package:flutter/foundation.dart';
import '../../../core/utils/api_error.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

/// Drives the client's Booking History / Booking Details screens.
class BookingController extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<BookingModel> bookings = [];
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  /// Bookings in [statuses], newest scheduled first — what each history tab
  /// shows. An empty list means "every status".
  List<BookingModel> withStatus(List<BookingStatus> statuses) {
    final matching = statuses.isEmpty
        ? [...bookings]
        : bookings.where((b) => statuses.contains(b.status)).toList();
    matching.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
    return matching;
  }

  Future<void> loadClientBookings() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      bookings = await _bookingService.getClientBookings();
    } catch (e) {
      bookings = [];
      errorMessage = apiErrorMessage(e, 'Unable to load your bookings.');
    }
    isLoading = false;
    notifyListeners();
  }

  /// One booking, fresh from the API. Returns null and sets [errorMessage]
  /// when it cannot be read.
  Future<BookingModel?> loadBooking(String id) async {
    try {
      final booking = await _bookingService.getClientBooking(id);
      _replace(booking);
      return booking;
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to load this booking.');
      notifyListeners();
      return null;
    }
  }

  /// Cancels a pending or confirmed booking. Returns the updated booking, or
  /// null when the API refused it (reason in [errorMessage]).
  Future<BookingModel?> cancel(String bookingId, {String? reason}) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final cancelled = await _bookingService.cancelBooking(bookingId, reason: reason);
      _replace(cancelled);
      return cancelled;
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to cancel this booking.');
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Moves a booking to [scheduledDate]. Returns the updated booking, or
  /// null when the API refused it — a taken window or a time outside the
  /// provider's hours — with the reason in [errorMessage].
  Future<BookingModel?> reschedule(String bookingId, DateTime scheduledDate) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final moved = await _bookingService.rescheduleBooking(bookingId, scheduledDate: scheduledDate);
      _replace(moved);
      return moved;
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to reschedule this booking.');
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Keeps the cached list in step with a booking the API just returned, so a
  /// status change shows up without refetching everything.
  void _replace(BookingModel booking) {
    final index = bookings.indexWhere((b) => b.id == booking.id);
    if (index == -1) {
      bookings = [booking, ...bookings];
    } else {
      bookings = [...bookings]..[index] = booking;
    }
    notifyListeners();
  }
}
