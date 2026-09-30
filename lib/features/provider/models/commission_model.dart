/// What the signed-in provider owes SkillServe, from
/// `GET /api/client/v1/provider/commissions`
/// (api-docs/modules/provider-commissions.md).
///
/// SkillServe's commission is contained *within* the price the provider
/// advertises — it is never added on top of what the customer pays. Because
/// the customer pays the provider directly, the provider collects the whole
/// amount and then owes the platform's share back.
///
/// Money amounts stay as the API formatted them (`"20.00"`): they are shown,
/// never arithmetic, and re-parsing a decimal for display only invites
/// rounding differences between the app and the ledger.
class CommissionSummary {
  final bool eligible;

  /// Why the provider is blocked, or null. `outstanding_commission` is the
  /// one this screen can do anything about; an identity reason means the
  /// National ID screen is the right place instead.
  final String? reason;

  final String outstandingTotal;
  final int outstandingCount;
  final String currency;
  final List<OutstandingCommission> outstanding;

  const CommissionSummary({
    this.eligible = true,
    this.reason,
    this.outstandingTotal = '0.00',
    this.outstandingCount = 0,
    this.currency = 'PHP',
    this.outstanding = const [],
  });

  /// Whether the commission debt in particular is what is blocking work.
  bool get isBlockedByCommission => reason == 'outstanding_commission';

  bool get hasOutstanding => outstandingCount > 0;

  factory CommissionSummary.fromJson(Map<String, dynamic> json) => CommissionSummary(
        eligible: json['eligible'] == true,
        reason: json['reason'] as String?,
        outstandingTotal: json['outstanding_total']?.toString() ?? '0.00',
        outstandingCount: (json['outstanding_count'] as num?)?.toInt() ?? 0,
        currency: json['currency'] as String? ?? 'PHP',
        outstanding: [
          for (final item in (json['outstanding'] as List? ?? const []))
            OutstandingCommission.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
      );
}

/// One paid job whose commission has not been remitted yet.
class OutstandingCommission {
  final String bookingNumber;
  final String serviceTitle;
  final String totalPrice;
  final String commissionRate;
  final String commissionAmount;

  /// When the customer's payment was recorded — the point the debt started.
  final DateTime? paidAt;

  const OutstandingCommission({
    this.bookingNumber = '',
    this.serviceTitle = '',
    this.totalPrice = '0.00',
    this.commissionRate = '0.00',
    this.commissionAmount = '0.00',
    this.paidAt,
  });

  factory OutstandingCommission.fromJson(Map<String, dynamic> json) => OutstandingCommission(
        bookingNumber: json['booking_number'] as String? ?? '',
        serviceTitle: json['service'] as String? ?? 'Service',
        totalPrice: json['total_price']?.toString() ?? '0.00',
        commissionRate: json['commission_rate']?.toString() ?? '0.00',
        commissionAmount: json['commission_amount']?.toString() ?? '0.00',
        paidAt: json['paid_at'] is String
            ? DateTime.tryParse(json['paid_at'] as String)?.toLocal()
            : null,
      );
}
