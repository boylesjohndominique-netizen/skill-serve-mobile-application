import '../data/mock/mock_data.dart';
import '../models/booking_model.dart';
import 'api_client.dart';

/// Placeholder service for the booking lifecycle.
class BookingService {
  // GET /bookings?role=client
  Future<List<BookingModel>> getClientBookings() async {
    await simulateNetworkDelay();
    return MockData.bookingsForClient;
  }

  // GET /bookings?role=provider
  Future<List<BookingModel>> getProviderBookings() async {
    await simulateNetworkDelay();
    return MockData.bookingsForProvider;
  }

  // POST /bookings
  Future<BookingModel> createBooking({
    required String providerId,
    required String serviceId,
    required String serviceTitle,
    required double amount,
    required DateTime date,
    required String schedule,
    required String address,
    required String paymentMethod,
    String? notes,
    String? clientName,
  }) async {
    await simulateNetworkDelay(ms: 700);
    final provider = MockData.providers.firstWhere((p) => p.id == providerId);
    final name = clientName ?? MockData.currentClient.fullName;
    return BookingModel(
      id: 'BK-${DateTime.now().millisecondsSinceEpoch}',
      clientId: MockData.currentClient.id,
      clientName: name,
      providerId: providerId,
      providerName: provider.user.fullName,
      serviceId: serviceId,
      serviceTitle: serviceTitle.isEmpty ? '${provider.categoryName} Service' : serviceTitle,
      bookingDate: date,
      schedule: schedule,
      status: BookingStatus.pending,
      amount: amount,
      address: address,
      notes: notes,
      paymentMethod: paymentMethod,
      timeline: [
        BookingTimelineEntry(label: 'Booking requested', at: DateTime.now(), status: 'pending'),
      ],
    );
  }

  // PATCH /bookings/:id/cancel
  Future<void> cancelBooking(String id) async => simulateNetworkDelay(ms: 300);

  // PATCH /bookings/:id/accept  (provider)
  Future<void> acceptBooking(String id) async => simulateNetworkDelay(ms: 300);

  // PATCH /bookings/:id/decline  (provider)
  Future<void> declineBooking(String id) async => simulateNetworkDelay(ms: 300);

  // PATCH /bookings/:id/start  (provider: confirmed → in_progress)
  Future<void> startBooking(String id) async => simulateNetworkDelay(ms: 300);

  // PATCH /bookings/:id/complete (provider)
  Future<void> completeBooking(String id) async => simulateNetworkDelay(ms: 300);

  // POST /bookings/:id/dispute  (client)
  Future<void> disputeBooking(String id) async => simulateNetworkDelay(ms: 300);
}
