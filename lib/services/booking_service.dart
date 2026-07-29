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
    required DateTime date,
    required String schedule,
    required String address,
    String? notes,
  }) async {
    await simulateNetworkDelay(ms: 700);
    final provider = MockData.providers.firstWhere((p) => p.id == providerId);
    return BookingModel(
      id: 'BK-${DateTime.now().millisecondsSinceEpoch}',
      clientId: MockData.currentClient.id,
      clientName: MockData.currentClient.fullName,
      providerId: providerId,
      providerName: provider.user.fullName,
      serviceId: serviceId,
      serviceTitle: '${provider.categoryName} Service',
      bookingDate: date,
      schedule: schedule,
      status: BookingStatus.pending,
      amount: provider.startingPrice ?? 500,
      address: address,
      notes: notes,
    );
  }

  // PATCH /bookings/:id/cancel
  Future<void> cancelBooking(String id) async => simulateNetworkDelay(ms: 300);

  // PATCH /bookings/:id/accept  (provider)
  Future<void> acceptBooking(String id) async => simulateNetworkDelay(ms: 300);

  // PATCH /bookings/:id/complete (provider)
  Future<void> completeBooking(String id) async => simulateNetworkDelay(ms: 300);
}
