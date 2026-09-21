import 'package:intl/intl.dart';

/// Booking lifecycle. The API calls the in-progress state `active`; the app
/// keeps the clearer `inProgress` name and translates at the boundary.
enum BookingStatus { pending, confirmed, inProgress, completed, cancelled, disputed }

/// One step in the booking's status timeline (e.g. "Requested", "Accepted").
class BookingTimelineEntry {
  final String label;
  final DateTime at;
  final String status; // BookingStatus name for coloring

  const BookingTimelineEntry({required this.label, required this.at, required this.status});
}

/// A booking as the client API returns it.
///
/// Parses both client payloads (`ClientBooking`, which carries the
/// `provider` block) and provider payloads (`ProviderBooking`, which carries
/// the `client` block instead) — the shapes are otherwise identical, so one
/// model serves the customer's Booking History and the provider's job lists.
class BookingModel {
  static final _time = DateFormat('h:mm a');

  final String id;
  final String bookingNumber;
  final String clientId;
  final String clientName;
  final String? clientAvatar;
  final String clientPhone;
  final String providerId;
  final String providerName;
  final String? providerAvatar;
  final String serviceId;
  final String serviceTitle;
  final String serviceDuration;

  /// Start of the booked window — the "date" every screen shows.
  final DateTime bookingDate;
  final DateTime? scheduledEndDate;
  final BookingStatus status;
  final String paymentStatus;

  /// `total_price` — what the customer owes for the job.
  final double amount;

  /// SkillServe's cut of [amount]. Only the provider's payload carries it, so
  /// it reads as zero on the customer's side, where it is not shown.
  final double platformFee;
  final String currency;
  final String address;
  final String? notes;
  final String? cancellationReason;

  /// API enum value (`cash`, `gcash`, …); null when none was chosen.
  final String? paymentMethodCode;
  final bool isReviewed;
  final DateTime? confirmedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    this.bookingNumber = '',
    this.clientId = '',
    this.clientName = '',
    this.clientAvatar,
    this.clientPhone = '',
    this.providerId = '',
    this.providerName = '',
    this.providerAvatar,
    required this.serviceId,
    required this.serviceTitle,
    this.serviceDuration = '',
    required this.bookingDate,
    this.scheduledEndDate,
    required this.status,
    this.paymentStatus = 'unpaid',
    required this.amount,
    this.platformFee = 0,
    this.currency = 'PHP',
    this.address = '',
    this.notes,
    this.cancellationReason,
    this.paymentMethodCode,
    this.isReviewed = false,
    this.confirmedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    required this.createdAt,
  });

  /// The booked window as "9:00 AM – 11:00 AM", or just the start time when
  /// the API sent no end.
  String get schedule {
    final start = _time.format(bookingDate);
    final end = scheduledEndDate;
    return end == null ? start : '$start – ${_time.format(end)}';
  }

  /// Display label for the chosen payment method, e.g. "Cash on hand".
  String get paymentMethod => paymentMethodLabel(paymentMethodCode);

  bool get isCancellable =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;

  bool get canBeReviewed => status == BookingStatus.completed && !isReviewed;

  /// What the provider keeps from this job once the platform fee is taken.
  double get providerEarnings => (amount - platformFee).clamp(0, double.infinity).toDouble();

  bool get isPaid => paymentStatus == 'paid';

  /// Status history built from the timestamps the API records, oldest first.
  List<BookingTimelineEntry> get timeline => [
        BookingTimelineEntry(label: 'Requested', at: createdAt, status: 'pending'),
        if (confirmedAt != null)
          BookingTimelineEntry(label: 'Accepted', at: confirmedAt!, status: 'confirmed'),
        if (startedAt != null)
          BookingTimelineEntry(label: 'Job started', at: startedAt!, status: 'inProgress'),
        if (completedAt != null)
          BookingTimelineEntry(label: 'Completed', at: completedAt!, status: 'completed'),
        if (cancelledAt != null)
          BookingTimelineEntry(label: 'Cancelled', at: cancelledAt!, status: 'cancelled'),
      ];

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>?;
    // A client payload names the provider directly; a provider payload only
    // carries it nested under the service.
    final provider = (json['provider'] ?? service?['provider']) as Map<String, dynamic>?;
    final client = json['client'] as Map<String, dynamic>?;
    final scheduled = _date(json['scheduled_date']);
    final created = _date(json['created_at']);

    return BookingModel(
      id: json['id'].toString(),
      bookingNumber: json['booking_number'] as String? ?? '',
      clientId: client?['id']?.toString() ?? '',
      clientName: client?['name'] as String? ?? '',
      clientAvatar: client?['profile_picture'] as String?,
      clientPhone: client?['phone'] as String? ?? json['contact_phone'] as String? ?? '',
      providerId: provider?['id']?.toString() ?? '',
      providerName: provider?['business_name'] as String? ?? '',
      serviceId: service?['id']?.toString() ?? '',
      serviceTitle: service?['title'] as String? ?? '',
      serviceDuration: service?['duration'] as String? ?? '',
      // A booking always has a scheduled start; falling back to the creation
      // time keeps a list from reordering between reads.
      bookingDate: scheduled ?? created ?? DateTime.now(),
      scheduledEndDate: _date(json['scheduled_end_date']),
      status: statusFromApi(json['status'] as String?),
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      amount: _money(json['total_price']) ?? _money(json['service_price']) ?? 0,
      platformFee: _money(json['platform_fee']) ?? 0,
      currency: json['currency'] as String? ?? 'PHP',
      address: json['service_address'] as String? ?? '',
      notes: json['client_notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      paymentMethodCode: json['payment_method'] as String?,
      isReviewed: json['is_reviewed'] == true,
      confirmedAt: _date(json['confirmed_at']),
      startedAt: _date(json['started_at']),
      completedAt: _date(json['completed_at']),
      cancelledAt: _date(json['cancelled_at']),
      createdAt: created ?? scheduled ?? DateTime.now(),
    );
  }

  /// Payment methods the API accepts, as (code, label) pairs in the order the
  /// booking form offers them.
  static const paymentMethods = <(String, String)>[
    ('cash', 'Cash on hand'),
    ('gcash', 'GCash'),
    ('credit_card', 'Credit card'),
    ('debit_card', 'Debit card'),
    ('bank_transfer', 'Bank transfer'),
    ('paypal', 'PayPal'),
  ];

  static String paymentMethodLabel(String? code) {
    for (final method in paymentMethods) {
      if (method.$1 == code) return method.$2;
    }
    return code == null || code.isEmpty ? 'Not selected' : code;
  }

  /// `active` on the wire is `inProgress` in the app; an unknown status reads
  /// as pending rather than crashing the list.
  static BookingStatus statusFromApi(String? status) {
    return switch (status) {
      'confirmed' => BookingStatus.confirmed,
      'active' => BookingStatus.inProgress,
      'completed' => BookingStatus.completed,
      'cancelled' => BookingStatus.cancelled,
      'disputed' => BookingStatus.disputed,
      _ => BookingStatus.pending,
    };
  }

  static String statusToApi(BookingStatus status) {
    return status == BookingStatus.inProgress ? 'active' : status.name;
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  /// Laravel serializes `decimal:2` casts as strings ("1500.00").
  static double? _money(Object? value) => switch (value) {
        num n => n.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };
}
