enum BookingStatus { pending, confirmed, inProgress, completed, cancelled, disputed }

/// One step in the booking's status timeline (e.g. "Requested", "Accepted").
class BookingTimelineEntry {
  final String label;
  final DateTime at;
  final String status; // BookingStatus name for coloring

  const BookingTimelineEntry({required this.label, required this.at, required this.status});
}

/// Mirrors the `bookings` table, denormalized with display names for the UI.
class BookingModel {
  final String id;
  final String clientId;
  final String clientName;
  final String providerId;
  final String providerName;
  final String? providerAvatar;
  final String serviceId;
  final String serviceTitle;
  final DateTime bookingDate;
  final String schedule;
  final BookingStatus status;
  final double amount;
  final String address;
  final String? notes;
  final String paymentMethod; // GCash | Maya | Cash on hand | Card
  final List<BookingTimelineEntry> timeline;

  const BookingModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.providerId,
    required this.providerName,
    this.providerAvatar,
    required this.serviceId,
    required this.serviceTitle,
    required this.bookingDate,
    required this.schedule,
    required this.status,
    required this.amount,
    this.address = '',
    this.notes,
    this.paymentMethod = 'Cash on hand',
    this.timeline = const [],
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel(
        id: json['booking_id'].toString(),
        clientId: json['client_id'].toString(),
        clientName: json['client_name'] as String? ?? '',
        providerId: json['provider_id'].toString(),
        providerName: json['provider_name'] as String? ?? '',
        providerAvatar: json['provider_avatar'] as String?,
        serviceId: json['service_id'].toString(),
        serviceTitle: json['service_title'] as String? ?? '',
        bookingDate: DateTime.tryParse(json['booking_date'] as String? ?? '') ?? DateTime.now(),
        schedule: json['schedule'] as String? ?? '',
        status: BookingStatus.values.byName(json['status'] as String? ?? 'pending'),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        address: json['address'] as String? ?? '',
        notes: json['notes'] as String?,
        paymentMethod: json['payment_method'] as String? ?? 'Cash on hand',
        timeline: (json['timeline'] as List?)
                ?.map((e) => BookingTimelineEntry(
                      label: e['label'] as String? ?? '',
                      at: DateTime.tryParse(e['at'] as String? ?? '') ?? DateTime.now(),
                      status: e['status'] as String? ?? 'pending',
                    ))
                .toList() ??
            const [],
      );
}
