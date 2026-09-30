import 'dart:typed_data';

/// The signed-in account's National ID verification, as
/// `GET /api/client/v1/identity-verification` returns it.
///
/// The API only ever sends back the last four digits of the card number, so
/// that is all this model can hold — there is deliberately no field for the
/// full number.
class IdentityVerification {
  /// `unverified`, `pending`, `verified` or `rejected`.
  final String status;

  /// Whether the holder may submit now (not while pending or once verified).
  final bool canSubmit;

  /// Last four digits only, e.g. `4821`.
  final String? idNumberLast4;
  final String? fullName;
  final DateTime? birthdate;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  /// Why it was turned down, shown so the holder can fix it and resubmit.
  final String? rejectionReason;

  const IdentityVerification({
    required this.status,
    this.canSubmit = false,
    this.idNumberLast4,
    this.fullName,
    this.birthdate,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
  });

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isUnverified => status == 'unverified';

  factory IdentityVerification.fromJson(Map<String, dynamic> json) => IdentityVerification(
        status: json['status'] as String? ?? 'unverified',
        canSubmit: json['can_submit'] == true,
        idNumberLast4: json['id_number_last4'] as String?,
        fullName: json['full_name'] as String?,
        birthdate: _date(json['birthdate']),
        submittedAt: _date(json['submitted_at']),
        reviewedAt: _date(json['reviewed_at']),
        rejectionReason: json['rejection_reason'] as String?,
      );
}

/// Whether this account may transact, and what is stopping it.
///
/// From `GET /api/client/v1/transaction-eligibility`. Advisory only — every
/// protected endpoint re-checks server-side — but it is what lets the app show
/// the right prompt instead of a bare 403.
class TransactionEligibility {
  final bool eligible;

  /// `identity_unverified`, `identity_pending`, `identity_rejected`,
  /// `outstanding_commission`, `no_provider_profile`, or null when eligible.
  final String? reason;

  final String identityStatus;

  /// Whether this account falls under the National ID requirement at all.
  /// Accounts created before the platform's cutover date do not.
  final bool identityRequired;

  /// Providers only: what they still owe the platform.
  final String outstandingTotal;
  final int outstandingCount;

  const TransactionEligibility({
    required this.eligible,
    this.reason,
    this.identityStatus = 'unverified',
    this.identityRequired = false,
    this.outstandingTotal = '0.00',
    this.outstandingCount = 0,
  });

  /// Nothing is required of a brand-new install until the API says otherwise;
  /// assuming a block would lock people out of a platform that does not
  /// require verification.
  static const unknown = TransactionEligibility(eligible: true);

  bool get blockedByIdentity => !eligible && (reason?.startsWith('identity_') ?? false);
  bool get blockedByCommission => reason == 'outstanding_commission';

  factory TransactionEligibility.fromJson(Map<String, dynamic> json) => TransactionEligibility(
        eligible: json['eligible'] == true,
        reason: json['reason'] as String?,
        identityStatus: json['identity_status'] as String? ?? 'unverified',
        identityRequired: json['identity_required'] == true,
        outstandingTotal: json['outstanding_total']?.toString() ?? '0.00',
        outstandingCount: (json['outstanding_count'] as num?)?.toInt() ?? 0,
      );
}

/// One side of the card the holder has captured but not submitted yet.
class PendingIdentityDocument {
  /// `id_front`, `id_back` or `selfie`.
  final String type;
  final String fileName;
  final Uint8List bytes;

  const PendingIdentityDocument({
    required this.type,
    required this.fileName,
    required this.bytes,
  });

  /// The API takes JPG, PNG and PDF up to 10 MB each.
  static const maxBytes = 10 * 1024 * 1024;
  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

  static const frontType = 'id_front';
  static const backType = 'id_back';
  static const selfieType = 'selfie';

  static String label(String type) => switch (type) {
        frontType => 'Front of card',
        backType => 'Back of card',
        selfieType => 'Selfie',
        _ => 'Document',
      };
}

DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;
