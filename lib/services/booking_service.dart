import '../models/booking_model.dart';
import 'api_client.dart';

/// Service for the booking lifecycle — live API only.
///
/// Endpoints:
/// - GET /api/client/v1/bookings
/// - POST /api/client/v1/bookings
/// - GET /api/client/v1/bookings/{booking}
/// - PATCH /api/client/v1/bookings/{booking}/cancel
class BookingService {
  // GET /api/client/v1/bookings
  Future<List<BookingModel>> getClientBookings() async {
    final response =
        await ApiClient.instance.dio.get('/client/v1/bookings');
    final data = response.data['data'];
    final items = data is List
        ? data
        : data is Map<String, dynamic>
            ? data['data'] as List? ?? []
            : [];
    return items
        .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // No documented client endpoint for provider bookings.
  Future<List<BookingModel>> getProviderBookings() async {
    throw UnsupportedError(
        'Provider bookings endpoint is not documented for clients.');
  }

  // POST /api/client/v1/bookings
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
    final response = await ApiClient.instance.dio.post(
      '/client/v1/bookings',
      data: {
        'service_id': int.parse(serviceId),
        'scheduled_date': date.toIso8601String(),
        'client_notes': notes,
        'payment_method': paymentMethod,
      },
    );
    return BookingModel.fromJson(
        response.data['data'] as Map<String, dynamic>);
  }

  // PATCH /api/client/v1/bookings/{booking}/cancel
  Future<void> cancelBooking(String id) async {
    await ApiClient.instance.dio.patch('/client/v1/bookings/$id/cancel');
  }

  // No documented client endpoint for accept/decline/start/complete/dispute.
  Future<void> acceptBooking(String id) async {
    throw UnsupportedError('Booking accept is not documented for clients.');
  }

  Future<void> declineBooking(String id) async {
    throw UnsupportedError('Booking decline is not documented for clients.');
  }

  Future<void> startBooking(String id) async {
    throw UnsupportedError('Booking start is not documented for clients.');
  }

  Future<void> completeBooking(String id) async {
    throw UnsupportedError('Booking complete is not documented for clients.');
  }

  Future<void> disputeBooking(String id) async {
    throw UnsupportedError('Booking dispute is not documented for clients.');
  }
}
