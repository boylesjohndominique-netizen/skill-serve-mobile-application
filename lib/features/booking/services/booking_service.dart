import 'package:dio/dio.dart';

import '../models/booking_model.dart';
import '../../../core/services/api_client.dart';

/// Service for the booking lifecycle — live API only.
///
/// Customer endpoints (api-docs/modules/client-bookings.md):
/// - GET   /api/client/v1/bookings
/// - POST  /api/client/v1/bookings
/// - GET   /api/client/v1/bookings/{booking}
/// - PATCH /api/client/v1/bookings/{booking}/cancel
/// - PATCH /api/client/v1/bookings/{booking}/reschedule
///
/// Provider endpoints (api-docs/modules/provider-bookings.md):
/// - GET   /api/client/v1/provider/bookings
/// - GET   /api/client/v1/provider/bookings/{booking}
/// - PATCH /api/client/v1/provider/bookings/{booking}/confirm
/// - PATCH /api/client/v1/provider/bookings/{booking}/decline
/// - PATCH /api/client/v1/provider/bookings/{booking}/cancel
/// - PATCH /api/client/v1/provider/bookings/{booking}/start
/// - PATCH /api/client/v1/provider/bookings/{booking}/complete
/// - PATCH /api/client/v1/provider/bookings/{booking}/payment-received
class BookingService {
  static const _clientBase = '/client/v1/bookings';
  static const _providerBase = '/client/v1/provider/bookings';

  /// The largest page the API allows, so the history and job screens can
  /// split bookings by status client-side from a single read.
  static const _perPage = 100;

  // ── Customer ──

  /// GET /api/client/v1/bookings. [status] filters server-side when given.
  Future<List<BookingModel>> getClientBookings({BookingStatus? status}) {
    return _list(_clientBase, status);
  }

  /// GET /api/client/v1/bookings/{booking}
  Future<BookingModel> getClientBooking(String id) {
    return _one('$_clientBase/$id');
  }

  /// POST /api/client/v1/bookings. [idempotencyKey] makes a retried submit
  /// return the booking already created instead of a second one.
  Future<BookingModel> createBooking({
    required String serviceId,
    required DateTime scheduledDate,
    DateTime? scheduledEndDate,
    String? notes,
    String? paymentMethod,
    String? serviceAddress,
    Map<String, dynamic>? serviceAddressDetails,
    String? contactPhone,
    String? idempotencyKey,
  }) async {
    final response = await ApiClient.instance.dio.post(
      _clientBase,
      data: {
        'service_id': int.parse(serviceId),
        'scheduled_date': BookingModel.apiDateTime(scheduledDate),
        if (scheduledEndDate != null) 'scheduled_end_date': BookingModel.apiDateTime(scheduledEndDate),
        if (notes != null && notes.isNotEmpty) 'client_notes': notes,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        // The structured address; the API writes service_address from it.
        if (serviceAddressDetails != null)
          'service_address_details': serviceAddressDetails
        else if (serviceAddress != null && serviceAddress.isNotEmpty)
          'service_address': serviceAddress,
        if (contactPhone != null && contactPhone.isNotEmpty) 'contact_phone': contactPhone,
      },
      options: idempotencyKey == null
          ? null
          : Options(headers: {'Idempotency-Key': idempotencyKey}),
    );
    return BookingModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// PATCH /api/client/v1/bookings/{booking}/cancel
  Future<BookingModel> cancelBooking(String id, {String? reason}) {
    return _transition('$_clientBase/$id/cancel', reason: reason);
  }

  /// PATCH /api/client/v1/bookings/{booking}/reschedule — move a pending or
  /// confirmed booking. Without [scheduledEndDate] it keeps its length; a
  /// confirmed booking comes back pending for the provider to accept again.
  Future<BookingModel> rescheduleBooking(
    String id, {
    required DateTime scheduledDate,
    DateTime? scheduledEndDate,
  }) async {
    final response = await ApiClient.instance.dio.patch(
      '$_clientBase/$id/reschedule',
      data: {
        'scheduled_date': BookingModel.apiDateTime(scheduledDate),
        if (scheduledEndDate != null) 'scheduled_end_date': BookingModel.apiDateTime(scheduledEndDate),
      },
    );
    return BookingModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // ── Provider ──

  /// GET /api/client/v1/provider/bookings
  Future<List<BookingModel>> getProviderBookings({BookingStatus? status}) {
    return _list(_providerBase, status);
  }

  /// GET /api/client/v1/provider/bookings/{booking}
  Future<BookingModel> getProviderBooking(String id) {
    return _one('$_providerBase/$id');
  }

  /// PATCH …/confirm — accept a pending request.
  Future<BookingModel> acceptBooking(String id) {
    return _transition('$_providerBase/$id/confirm');
  }

  /// PATCH …/decline — refuse a pending request; [reason] reaches the client.
  Future<BookingModel> declineBooking(String id, {String? reason}) {
    return _transition('$_providerBase/$id/decline', reason: reason);
  }

  /// PATCH …/cancel — call off an accepted job before it starts. The API
  /// requires [reason]; it reaches the client.
  Future<BookingModel> cancelAcceptedBooking(String id, {required String reason}) {
    return _transition('$_providerBase/$id/cancel', reason: reason);
  }

  /// PATCH …/start — begin a confirmed job.
  Future<BookingModel> startBooking(String id) {
    return _transition('$_providerBase/$id/start');
  }

  /// PATCH …/complete — finish a job in progress.
  Future<BookingModel> completeBooking(String id) {
    return _transition('$_providerBase/$id/complete');
  }

  /// PATCH …/payment-received — the customer paid for a completed job.
  /// Nothing is charged; this records the off-platform payment.
  Future<BookingModel> recordPayment(String id, {String? reference}) async {
    final response = await ApiClient.instance.dio.patch(
      '$_providerBase/$id/payment-received',
      data: reference == null || reference.trim().isEmpty
          ? null
          : {'payment_reference': reference.trim()},
    );
    return BookingModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  // ── Shared plumbing ──

  Future<List<BookingModel>> _list(String path, BookingStatus? status) async {
    final response = await ApiClient.instance.dio.get(path, queryParameters: {
      'per_page': _perPage,
      if (status != null) 'status': BookingModel.statusToApi(status),
    });
    return [
      for (final item in response.data['data'] as List? ?? const [])
        BookingModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<BookingModel> _one(String path) async {
    final response = await ApiClient.instance.dio.get(path);
    return BookingModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Every status change returns the updated booking, so callers can replace
  /// their copy instead of refetching the whole list.
  Future<BookingModel> _transition(String path, {String? reason}) async {
    final response = await ApiClient.instance.dio.patch(
      path,
      data: reason == null || reason.trim().isEmpty ? null : {'reason': reason.trim()},
    );
    return BookingModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
