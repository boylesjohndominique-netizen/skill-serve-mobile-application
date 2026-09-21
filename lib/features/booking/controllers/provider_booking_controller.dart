import 'package:flutter/foundation.dart';
import '../../../core/utils/api_error.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

/// Drives the provider's Booking Requests / Active / Completed job screens,
/// plus the dashboard, calendar and earnings views that read the same list.
class ProviderBookingController extends ChangeNotifier {
  final BookingService _bookingService = BookingService();

  List<BookingModel> bookings = [];
  bool isLoading = false;

  /// The booking id currently being accepted, declined, started or completed
  /// — the screens disable that card's buttons while it is set.
  String? busyBookingId;
  String? errorMessage;

  Future<void> loadProviderBookings() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      bookings = await _bookingService.getProviderBookings();
    } catch (e) {
      bookings = [];
      errorMessage = apiErrorMessage(e, 'Unable to load your bookings.');
    }
    isLoading = false;
    notifyListeners();
  }

  /// Bookings in [statuses], soonest scheduled first — a provider works
  /// forwards through their day, unlike the customer's newest-first history.
  List<BookingModel> withStatus(List<BookingStatus> statuses) {
    final matching = statuses.isEmpty
        ? [...bookings]
        : bookings.where((b) => statuses.contains(b.status)).toList();
    matching.sort((a, b) => a.bookingDate.compareTo(b.bookingDate));
    return matching;
  }

  List<BookingModel> get requests => withStatus([BookingStatus.pending]);

  List<BookingModel> get active =>
      withStatus([BookingStatus.confirmed, BookingStatus.inProgress]);

  List<BookingModel> get completed => withStatus([BookingStatus.completed]);

  /// One booking, fresh from the API, for the details screen.
  Future<BookingModel?> loadBooking(String id) async {
    try {
      final booking = await _bookingService.getProviderBooking(id);
      _replace(booking);
      return booking;
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to load this booking.');
      notifyListeners();
      return null;
    }
  }

  /// Each action returns true on success; on failure [errorMessage] explains
  /// why — usually that the booking already moved on.
  Future<bool> accept(String id) =>
      _transition(id, () => _bookingService.acceptBooking(id), 'Unable to accept this booking.');

  Future<bool> decline(String id, {String? reason}) => _transition(
        id,
        () => _bookingService.declineBooking(id, reason: reason),
        'Unable to decline this booking.',
      );

  /// Calls off an accepted job before it starts; [reason] is required.
  Future<bool> cancel(String id, {required String reason}) => _transition(
        id,
        () => _bookingService.cancelAcceptedBooking(id, reason: reason),
        'Unable to cancel this job.',
      );

  Future<bool> start(String id) =>
      _transition(id, () => _bookingService.startBooking(id), 'Unable to start this job.');

  Future<bool> complete(String id) =>
      _transition(id, () => _bookingService.completeBooking(id), 'Unable to complete this job.');

  /// Records that the customer paid for a completed job; [reference] is an
  /// optional GCash or transfer number.
  Future<bool> recordPayment(String id, {String? reference}) => _transition(
        id,
        () => _bookingService.recordPayment(id, reference: reference),
        'Unable to record this payment.',
      );

  Future<bool> _transition(
    String id,
    Future<BookingModel> Function() action,
    String fallback,
  ) async {
    busyBookingId = id;
    errorMessage = null;
    notifyListeners();
    try {
      _replace(await action());
      return true;
    } catch (e) {
      errorMessage = apiErrorMessage(e, fallback);
      return false;
    } finally {
      busyBookingId = null;
      notifyListeners();
    }
  }

  /// Swaps in the booking the API just returned so the card moves to its new
  /// tab immediately, without refetching the whole list.
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
