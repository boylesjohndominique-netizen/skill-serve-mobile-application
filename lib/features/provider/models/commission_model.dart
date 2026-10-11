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

  /// SkillServe's GCash, where the commission is sent.
  final CommissionPaymentAccount paymentAccount;

  /// The provider's most recent GCash payment, whatever became of it.
  final CommissionRemittance? latestRemittance;

  const CommissionSummary({
    this.eligible = true,
    this.reason,
    this.outstandingTotal = '0.00',
    this.outstandingCount = 0,
    this.currency = 'PHP',
    this.outstanding = const [],
    this.paymentAccount = const CommissionPaymentAccount(),
    this.latestRemittance,
  });

  /// Whether the commission debt in particular is what is blocking work.
  bool get isBlockedByCommission => reason == 'outstanding_commission';

  bool get hasOutstanding => outstandingCount > 0;

  /// A payment is with SkillServe for confirmation, so another cannot be
  /// submitted yet.
  bool get hasPendingRemittance => latestRemittance?.isPending ?? false;

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
        paymentAccount: json['payment_account'] is Map
            ? CommissionPaymentAccount.fromJson(Map<String, dynamic>.from(json['payment_account'] as Map))
            : const CommissionPaymentAccount(),
        latestRemittance: json['latest_remittance'] is Map
            ? CommissionRemittance.fromJson(Map<String, dynamic>.from(json['latest_remittance'] as Map))
            : null,
      );
}

/// SkillServe's GCash account, as an administrator set it in System
/// Settings → Commission payments.
class CommissionPaymentAccount {
  final String gcashAccountName;
  final String gcashNumber;
  final String paymentInstructions;

  /// False until both the name and the number are set.
  final bool configured;

  const CommissionPaymentAccount({
    this.gcashAccountName = '',
    this.gcashNumber = '',
    this.paymentInstructions = '',
    this.configured = false,
  });

  factory CommissionPaymentAccount.fromJson(Map<String, dynamic> json) => CommissionPaymentAccount(
        gcashAccountName: json['gcash_account_name'] as String? ?? '',
        gcashNumber: json['gcash_number'] as String? ?? '',
        paymentInstructions: json['payment_instructions'] as String? ?? '',
        configured: json['configured'] == true,
      );
}

/// A GCash commission payment the provider submitted, from
/// `POST`/`GET /api/client/v1/provider/commission-remittances`.
///
/// `pending` until an administrator finds the reference in SkillServe's GCash
/// history; `confirmed` settled the bookings it covered; `rejected` carries
/// the reason, and the provider may submit again.
class CommissionRemittance {
  final int id;
  final String status;
  final String reference;
  final String amountDue;
  final String amountSent;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  const CommissionRemittance({
    required this.id,
    this.status = 'pending',
    this.reference = '',
    this.amountDue = '0.00',
    this.amountSent = '0.00',
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
  });

  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  factory CommissionRemittance.fromJson(Map<String, dynamic> json) => CommissionRemittance(
        id: (json['id'] as num?)?.toInt() ?? 0,
        status: json['status'] as String? ?? 'pending',
        reference: json['reference'] as String? ?? '',
        amountDue: json['amount_due']?.toString() ?? '0.00',
        amountSent: json['amount_sent']?.toString() ?? '0.00',
        rejectionReason: json['rejection_reason'] as String?,
        submittedAt: json['submitted_at'] is String
            ? DateTime.tryParse(json['submitted_at'] as String)?.toLocal()
            : null,
        reviewedAt: json['reviewed_at'] is String
            ? DateTime.tryParse(json['reviewed_at'] as String)?.toLocal()
            : null,
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

/// How a price splits between SkillServe and the provider: from
/// `GET /api/client/v1/provider/commission-preview` while a price is being
/// typed, or the `earnings` block on each of the provider's services.
///
/// The commission comes out of the advertised price, so [netAmount] is what
/// the provider keeps. Indicative only: a booking snapshots the rate in force
/// when it is made. Amounts stay as the API formatted them.
class CommissionSplit {
  final String amount;
  final String commissionRate;
  final String commissionAmount;
  final String netAmount;

  const CommissionSplit({
    this.amount = '0.00',
    this.commissionRate = '0.00',
    this.commissionAmount = '0.00',
    this.netAmount = '0.00',
  });

  /// The rate without trailing zeros: `15.00` → `15%`, `12.50` → `12.5%`.
  String get rateLabel {
    final rate = double.tryParse(commissionRate) ?? 0;
    final text = rate.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    return '$text%';
  }

  factory CommissionSplit.fromJson(Map<String, dynamic> json) => CommissionSplit(
        // The preview names the base `amount`; a service's earnings name it `price`.
        amount: (json['amount'] ?? json['price'])?.toString() ?? '0.00',
        commissionRate: json['commission_rate']?.toString() ?? '0.00',
        commissionAmount: json['commission_amount']?.toString() ?? '0.00',
        netAmount: json['net_amount']?.toString() ?? '0.00',
      );
}
