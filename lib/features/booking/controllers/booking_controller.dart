import 'package:flutter/foundation.dart';
import '../../../core/utils/api_error.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';
import 'booking_change_signal.dart';

/// Drives the client's Booking History / Booking Details screens.
class BookingController extends ChangeNotifier with BookingChangeSignal {
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
  /// null when the API refused it — a time outside the provider's hours —
  /// with the reason in [errorMessage].
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

  /// Sends proof of a GCash payment. Returns the updated booking, or null
  /// when the API refused it (reason in [errorMessage]).
  Future<BookingModel?> sendPaymentProof(
    String bookingId, {
    required double amount,
    String? reference,
    required String screenshotPath,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final updated = await _bookingService.sendPaymentProof(
        bookingId,
        amount: amount,
        reference: reference,
        screenshotPath: screenshotPath,
      );
      _replace(updated);
      return updated;
    } catch (e) {
      errorMessage = apiErrorMessage(e, 'Unable to send this payment proof.');
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// The returned payment reached the customer.
  Future<BookingModel?> confirmRefund(String bookingId) =>
      _save(() => _bookingService.confirmRefund(bookingId), 'Unable to confirm the refund.');

  /// The returned payment did not arrive; SkillServe's team steps in.
  Future<BookingModel?> reportRefundNotReceived(String bookingId, {required String note}) =>
      _save(() => _bookingService.reportRefundNotReceived(bookingId, note: note), 'Unable to send this report.');

  Future<BookingModel?> _save(Future<BookingModel> Function() action, String fallback) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final updated = await action();
      _replace(updated);
      return updated;
    } catch (e) {
      errorMessage = apiErrorMessage(e, fallback);
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// The realtime push said [bookingId] changed: an open booking screen
  /// reloads it, and the list catches up without a loading state.
  Future<void> onRealtimeChange(String bookingId) async {
    signalBookingChanged(bookingId);
    try {
      bookings = await _bookingService.getClientBookings();
      notifyListeners();
    } catch (_) {
      // Keep what is on screen; the next visit reloads it.
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
