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

/// Where the customer sends the money for an unpaid GCash booking.
///
/// SkillServe is never in the payment path: the customer pays the provider
/// directly and the provider then remits SkillServe's commission (ADR-021).
/// So this carries the *provider's own* GCash details, which the API returns
/// only on the customer's own unpaid GCash booking.
///
/// [gcashNumber] is null when the provider has not saved their details yet;
/// [note] then explains what to do instead, so it is always worth showing.
class PaymentInstructions {
  final String method;
  final String? gcashNumber;
  final String? gcashName;

  /// The amount to send, as the API formatted it (e.g. "200.00").
  final String amount;

  /// The booking number, to put in the GCash message so the provider can
  /// match the payment to the job.
  final String reference;
  final String note;

  const PaymentInstructions({
    this.method = 'gcash',
    this.gcashNumber,
    this.gcashName,
    this.amount = '0.00',
    this.reference = '',
    required this.note,
  });

  /// Whether there is a number to send money to.
  bool get isPayable => (gcashNumber ?? '').isNotEmpty;

  factory PaymentInstructions.fromJson(Map<String, dynamic> json) => PaymentInstructions(
        method: json['method'] as String? ?? 'gcash',
        gcashNumber: json['gcash_number'] as String?,
        gcashName: json['gcash_name'] as String?,
        amount: json['amount']?.toString() ?? '0.00',
        reference: json['reference'] as String? ?? '',
        note: json['note'] as String? ?? '',
      );
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

  /// `unpaid`, `paid`, `partially_refunded` or `refunded`. Payment happens
  /// off-platform; the provider or an administrator records it.
  final String paymentStatus;

  /// When the payment was recorded; null while unpaid.
  final DateTime? paidAt;

  /// Total refunded so far (0 when none).
  final double refundedAmount;
  final String? refundReason;

  /// `total_price` — what the customer owes for the job.
  final double amount;

  /// SkillServe's cut of [amount]. Only the provider's payload carries it, so
  /// it reads as zero on the customer's side, where it is not shown.
  final double platformFee;
  final String currency;
  final String address;
  final String? notes;
  final String? cancellationReason;

  /// A late-cancellation fee recorded when the booking was cancelled.
  final double? cancellationFee;

  /// The cancellation rule and its cost right now, while cancelling is possible.
  final CancellationPolicy? cancellationPolicy;

  /// API enum value (`on_hand`, `gcash`, or a legacy code on an old
  /// booking); null when none was chosen.
  final String? paymentMethodCode;

  /// How to pay the provider, on the customer's own unpaid GCash booking.
  /// Absent on every other booking, and on the provider's payload.
  final PaymentInstructions? paymentInstructions;
  final bool isReviewed;
  final DateTime? confirmedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  /// When the customer last moved the booking to a new time; null if never.
  final DateTime? rescheduledAt;
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
    this.paidAt,
    this.refundedAmount = 0,
    this.refundReason,
    required this.amount,
    this.platformFee = 0,
    this.currency = 'PHP',
    this.address = '',
    this.notes,
    this.cancellationReason,
    this.cancellationFee,
    this.cancellationPolicy,
    this.paymentMethodCode,
    this.paymentInstructions,
    this.isReviewed = false,
    this.confirmedAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.rescheduledAt,
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

  /// The customer can move the booking until the provider starts the job.
  bool get isReschedulable => isCancellable;

  /// A pending request the customer moved — for the provider, a job they
  /// may have accepted before, now waiting on the new time.
  bool get isRescheduledRequest => status == BookingStatus.pending && rescheduledAt != null;

  /// Length of the booked window, or null when the API sent no end.
  Duration? get length => scheduledEndDate?.difference(bookingDate);

  bool get canBeReviewed => status == BookingStatus.completed && !isReviewed;

  /// What the provider keeps from this job once the platform fee is taken.
  double get providerEarnings => (amount - platformFee).clamp(0, double.infinity).toDouble();

  bool get isPaid => paymentStatus == 'paid';

  bool get isUnpaid => paymentStatus == 'unpaid';

  /// A finished job the provider can confirm they were paid for.
  bool get canRecordPayment => status == BookingStatus.completed && isUnpaid;

  /// "Paid", "Unpaid", "Refunded" or "Partly refunded".
  String get paymentLabel => switch (paymentStatus) {
        'paid' => 'Paid',
        'refunded' => 'Refunded',
        'partially_refunded' => 'Partly refunded',
        _ => 'Unpaid',
      };

  /// Status history built from the timestamps the API records, oldest first.
  List<BookingTimelineEntry> get timeline => [
        BookingTimelineEntry(label: 'Requested', at: createdAt, status: 'pending'),
        // A reschedule clears the earlier acceptance, so it always sits
        // before any "Accepted" entry that follows it.
        if (rescheduledAt != null)
          BookingTimelineEntry(label: 'Rescheduled', at: rescheduledAt!, status: 'pending'),
        if (confirmedAt != null)
          BookingTimelineEntry(label: 'Accepted', at: confirmedAt!, status: 'confirmed'),
        if (startedAt != null)
          BookingTimelineEntry(label: 'Job started', at: startedAt!, status: 'inProgress'),
        if (completedAt != null)
          BookingTimelineEntry(label: 'Completed', at: completedAt!, status: 'completed'),
        if (cancelledAt != null)
          BookingTimelineEntry(label: 'Cancelled', at: cancelledAt!, status: 'cancelled'),
        if (paidAt != null)
          BookingTimelineEntry(label: 'Payment recorded', at: paidAt!, status: 'completed'),
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
      paidAt: _date(json['paid_at']),
      refundedAmount: _money(json['refunded_amount']) ?? 0,
      refundReason: json['refund_reason'] as String?,
      amount: _money(json['total_price']) ?? _money(json['service_price']) ?? 0,
      platformFee: _money(json['platform_fee']) ?? 0,
      currency: json['currency'] as String? ?? 'PHP',
      address: json['service_address'] as String? ?? '',
      notes: json['client_notes'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      cancellationFee: _money(json['cancellation_fee']),
      cancellationPolicy: json['cancellation_policy'] is Map
          ? CancellationPolicy.fromJson(Map<String, dynamic>.from(json['cancellation_policy'] as Map))
          : null,
      paymentMethodCode: json['payment_method'] as String?,
      paymentInstructions: json['payment_instructions'] is Map
          ? PaymentInstructions.fromJson(
              Map<String, dynamic>.from(json['payment_instructions'] as Map))
          : null,
      isReviewed: json['is_reviewed'] == true,
      confirmedAt: _date(json['confirmed_at']),
      startedAt: _date(json['started_at']),
      completedAt: _date(json['completed_at']),
      cancelledAt: _date(json['cancelled_at']),
      rescheduledAt: _date(json['rescheduled_at']),
      createdAt: created ?? scheduled ?? DateTime.now(),
    );
  }

  /// Payment methods the API accepts, as (code, label) pairs in the order the
  /// booking form offers them.
  ///
  /// There are exactly two, matching `PaymentMethod` on the backend. Card,
  /// bank transfer and PayPal were never collected by SkillServe and are now
  /// refused with a 422, so offering them only produced failed bookings.
  static const paymentMethods = <(String, String)>[
    ('on_hand', 'On-hand payment'),
    ('gcash', 'GCash'),
  ];

  /// Methods that older builds sent, kept for display only: bookings made
  /// before the methods were trimmed still carry these codes, and the API
  /// deliberately does not rewrite them.
  static const _legacyPaymentMethods = <String, String>{
    'cash': 'On-hand payment',
    'credit_card': 'Credit card',
    'debit_card': 'Debit card',
    'bank_transfer': 'Bank transfer',
    'paypal': 'PayPal',
  };

  static String paymentMethodLabel(String? code) {
    for (final method in paymentMethods) {
      if (method.$1 == code) return method.$2;
    }
    final legacy = _legacyPaymentMethods[code];
    if (legacy != null) return legacy;
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

  /// How a picked schedule time is sent: the same instant in UTC with a
  /// `Z` suffix. A bare local time would be read as the server's zone.
  static String apiDateTime(DateTime value) => value.toUtc().toIso8601String();

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  /// Laravel serializes `decimal:2` casts as strings ("1500.00").
  static double? _money(Object? value) => switch (value) {
        num n => n.toDouble(),
        String s => double.tryParse(s),
        _ => null,
      };
}

/// The platform's cancellation rule as it applies to this booking now
/// (System Settings → Booking): cancelling a confirmed booking less than
/// [windowHours] before it starts is late and records [feeIfCancelledNow].
class CancellationPolicy {
  final int windowHours;
  final double feePercent;
  final bool isLate;
  final double feeIfCancelledNow;

  const CancellationPolicy({
    required this.windowHours,
    required this.feePercent,
    required this.isLate,
    required this.feeIfCancelledNow,
  });

  bool get chargesFee => isLate && feeIfCancelledNow > 0;

  factory CancellationPolicy.fromJson(Map<String, dynamic> json) => CancellationPolicy(
        windowHours: (json['window_hours'] as num?)?.toInt() ?? 0,
        feePercent: (json['fee_percent'] as num?)?.toDouble() ?? 0,
        isLate: json['is_late'] == true,
        feeIfCancelledNow: double.tryParse('${json['fee_if_cancelled_now'] ?? 0}') ?? 0,
      );
}
