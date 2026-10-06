/// Where a report has got to. Mirrors the API's `status`.
enum ReportStatus { pending, investigating, resolved, rejected }

/// Why someone is being reported. The value is the API enum key; the label is
/// what the form shows, so wording can change without invalidating stored data.
enum ReportReason {
  serviceQuality('service_quality', 'Service quality issue'),
  noShow('no_show', 'Provider didn\'t show up'),
  safetyConcern('safety_concern', 'Safety concern'),
  paymentDispute('payment_dispute', 'Payment dispute'),
  misleadingInformation('misleading_information', 'Misleading information'),
  harassment('harassment', 'Harassment or inappropriate behavior'),
  inappropriateContent('inappropriate_content', 'Offensive or inappropriate content'),
  spam('spam', 'Spam or fake'),
  other('other', 'Other');

  /// The reasons that make sense for a person on a booking.
  static const forPeople = [
    serviceQuality,
    noShow,
    safetyConcern,
    paymentDispute,
    misleadingInformation,
    harassment,
    other,
  ];

  /// The reasons that make sense for a service listing.
  static const forServices = [
    misleadingInformation,
    spam,
    inappropriateContent,
    safetyConcern,
    other,
  ];

  /// The reasons that make sense for a review or a message.
  static const forContent = [
    inappropriateContent,
    harassment,
    spam,
    misleadingInformation,
    other,
  ];

  const ReportReason(this.value, this.label);

  final String value;
  final String label;

  static ReportReason? fromValue(String? value) {
    for (final reason in ReportReason.values) {
      if (reason.value == value) return reason;
    }
    return null;
  }

  /// A readable label for a reason the app does not know, so an older build
  /// never shows a raw enum key.
  static String labelFor(String? value) =>
      fromValue(value)?.label ??
      (value == null || value.isEmpty
          ? 'Other'
          : value.replaceAll('_', ' ').replaceRange(0, 1, value[0].toUpperCase()));
}

/// A complaint the signed-in account filed, as `ClientReport` returns it.
class ReportModel {
  final String id;

  /// What was reported: `user`, `review` or `message`.
  final String subjectType;

  /// Who was reported (or wrote the review or message) — a name only.
  final String reportedName;

  /// The reported review or message text, so the reporter recognises it.
  final String? excerpt;
  final String reason;
  final String details;
  final ReportStatus status;

  /// What support concluded: the resolution note once upheld, or the reason it
  /// was rejected. Null while the report is still being reviewed.
  final String? outcome;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final DateTime? rejectedAt;

  const ReportModel({
    required this.id,
    this.subjectType = 'user',
    this.reportedName = '',
    this.excerpt,
    required this.reason,
    required this.details,
    required this.status,
    this.outcome,
    required this.createdAt,
    this.resolvedAt,
    this.rejectedAt,
  });

  String get reasonLabel => ReportReason.labelFor(reason);

  /// "About Juan", "Review by Juan", "Message from Juan" or "Service by …".
  String get subjectLabel {
    final name = reportedName.isEmpty ? null : reportedName;
    return switch (subjectType) {
      'review' => name == null ? 'A review' : 'Review by $name',
      'message' => name == null ? 'A message' : 'Message from $name',
      'service' => name == null ? 'A service' : 'Service by $name',
      _ => name == null ? 'Reported account' : 'About $name',
    };
  }

  bool get isOpen =>
      status == ReportStatus.pending || status == ReportStatus.investigating;

  /// When support last moved the case, for the status line.
  DateTime? get decidedAt => resolvedAt ?? rejectedAt;

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final reported = json['reported'] as Map<String, dynamic>?;

    return ReportModel(
      id: json['id'].toString(),
      subjectType: json['subject_type'] as String? ?? 'user',
      reportedName: reported?['name'] as String? ?? '',
      excerpt: reported?['excerpt'] as String?,
      reason: json['reason'] as String? ?? 'other',
      details: json['description'] as String? ?? '',
      status: statusFromApi(json['status'] as String?),
      outcome: json['outcome'] as String?,
      createdAt: _date(json['created_at']) ?? DateTime.now(),
      resolvedAt: _date(json['resolved_at']),
      rejectedAt: _date(json['rejected_at']),
    );
  }

  /// An unknown status reads as pending rather than crashing the list.
  static ReportStatus statusFromApi(String? status) => switch (status) {
        'investigating' => ReportStatus.investigating,
        'resolved' => ReportStatus.resolved,
        'rejected' => ReportStatus.rejected,
        _ => ReportStatus.pending,
      };

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}

/// A dispute on one of the account's bookings, as `BookingDispute` returns it.
///
/// A dispute is raised against a booking, so [bookingId] identifies the case.
class DisputeModel {
  final String bookingId;
  final String bookingNumber;
  final String bookingStatus;
  final String serviceTitle;
  final String providerName;
  final String reason;

  /// `pending`, `investigated`, `resolved`, `rejected` or `closed`.
  final String disputeStatus;

  /// What support decided, once there is a decision.
  final String? resolution;
  final DateTime? disputedAt;
  final DateTime? closedAt;

  /// Photos either side attached. The files themselves stay private.
  final List<DisputeEvidence> evidence;

  /// Whether the API will take another photo right now.
  final bool canAddEvidence;

  const DisputeModel({
    required this.bookingId,
    this.bookingNumber = '',
    this.bookingStatus = '',
    this.serviceTitle = '',
    this.providerName = '',
    this.reason = '',
    this.disputeStatus = 'pending',
    this.resolution,
    this.disputedAt,
    this.closedAt,
    this.evidence = const [],
    this.canAddEvidence = false,
  });

  bool get isOpen => disputeStatus == 'pending' || disputeStatus == 'investigated';

  factory DisputeModel.fromJson(Map<String, dynamic> json) => DisputeModel(
        bookingId: json['booking_id'].toString(),
        bookingNumber: json['booking_number'] as String? ?? '',
        bookingStatus: json['booking_status'] as String? ?? '',
        serviceTitle: json['service_title'] as String? ?? '',
        providerName: json['provider_name'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        disputeStatus: json['dispute_status'] as String? ?? 'pending',
        resolution: json['resolution'] as String?,
        disputedAt: ReportModel._date(json['disputed_at']),
        closedAt: ReportModel._date(json['closed_at']),
        evidence: [
          for (final item in (json['evidence'] as List? ?? const []))
            if (item is Map) DisputeEvidence.fromJson(Map<String, dynamic>.from(item)),
        ],
        canAddEvidence: json['can_add_evidence'] == true,
      );
}

/// One photo attached to a dispute.
class DisputeEvidence {
  final String id;
  final String label;

  /// `customer` or `provider`.
  final String uploadedByRole;
  final bool isMine;
  final DateTime? uploadedAt;

  const DisputeEvidence({
    required this.id,
    required this.label,
    this.uploadedByRole = '',
    this.isMine = false,
    this.uploadedAt,
  });

  factory DisputeEvidence.fromJson(Map<String, dynamic> json) => DisputeEvidence(
        id: json['id']?.toString() ?? '',
        label: json['label'] as String? ?? 'Photo',
        uploadedByRole: json['uploaded_by_role'] as String? ?? '',
        isMine: json['is_mine'] == true,
        uploadedAt: ReportModel._date(json['uploaded_at']),
      );
}
