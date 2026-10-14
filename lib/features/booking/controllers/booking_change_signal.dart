import 'package:flutter/foundation.dart';

/// "This booking changed" from the realtime push (`client.booking.changed`):
/// an open booking screen reloads when its id comes through, even when the
/// change — a new payment proof — leaves its status as it was. [changeCount]
/// moves on every signal, so the same booking changing twice is still seen.
mixin BookingChangeSignal on ChangeNotifier {
  String? changedBookingId;
  int changeCount = 0;

  void signalBookingChanged(String bookingId) {
    changedBookingId = bookingId;
    changeCount++;
    notifyListeners();
  }
}
