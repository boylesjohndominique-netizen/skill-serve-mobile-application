import 'dart:typed_data';

/// The signed-in provider's verification, as `GET /api/client/v1/provider/verification`
/// returns it: the profile status plus the latest request and its documents.
class ProviderVerification {
  /// `unverified`, `pending`, `verified`, `rejected` or `additional_info_required`.
  final String status;
  final DateTime? verifiedAt;

  /// Whether the provider may upload now (not while pending or once verified).
  final bool canSubmit;
  final VerificationRequestModel? request;

  const ProviderVerification({
    required this.status,
    this.verifiedAt,
    this.canSubmit = false,
    this.request,
  });

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get needsMoreInfo => status == 'additional_info_required';

  factory ProviderVerification.fromJson(Map<String, dynamic> json) => ProviderVerification(
        status: json['verification_status'] as String? ?? 'unverified',
        verifiedAt: _date(json['verified_at']),
        canSubmit: json['can_submit'] == true,
        request: json['request'] is Map<String, dynamic>
            ? VerificationRequestModel.fromJson(json['request'] as Map<String, dynamic>)
            : null,
      );
}

/// One verification request and the administrator's answer to it.
class VerificationRequestModel {
  final String id;
  final String status;
  final String? notes;
  final String? rejectionReason;
  final String? additionalInfoRequest;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final List<VerificationDocumentModel> documents;

  const VerificationRequestModel({
    required this.id,
    required this.status,
    this.notes,
    this.rejectionReason,
    this.additionalInfoRequest,
    this.submittedAt,
    this.reviewedAt,
    this.documents = const [],
  });

  factory VerificationRequestModel.fromJson(Map<String, dynamic> json) => VerificationRequestModel(
        id: json['id'].toString(),
        status: json['status'] as String? ?? 'pending',
        notes: json['notes'] as String?,
        rejectionReason: json['rejection_reason'] as String?,
        additionalInfoRequest: json['additional_info_request'] as String?,
        submittedAt: _date(json['submitted_at']),
        reviewedAt: _date(json['reviewed_at']),
        documents: [
          for (final item in json['documents'] as List? ?? const [])
            VerificationDocumentModel.fromJson(item as Map<String, dynamic>),
        ],
      );
}

/// A document already submitted — the API never returns where it is stored.
class VerificationDocumentModel {
  final String id;

  /// `government_id`, `certificate` or `other`.
  final String type;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final DateTime? createdAt;

  const VerificationDocumentModel({
    required this.id,
    required this.type,
    required this.fileName,
    this.mimeType = '',
    this.fileSize = 0,
    this.createdAt,
  });

  String get typeLabel => documentTypeLabel(type);

  bool get isPdf => mimeType == 'application/pdf' || fileName.toLowerCase().endsWith('.pdf');

  factory VerificationDocumentModel.fromJson(Map<String, dynamic> json) => VerificationDocumentModel(
        id: json['id'].toString(),
        type: json['document_type'] as String? ?? 'other',
        fileName: json['file_name'] as String? ?? '',
        mimeType: json['file_mime_type'] as String? ?? '',
        fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
        createdAt: _date(json['created_at']),
      );

  /// The types the API accepts, as (code, label) pairs.
  static const types = <(String, String)>[
    ('government_id', 'Government-issued ID'),
    ('certificate', 'Certificate or license'),
    ('other', 'Other supporting document'),
  ];

  static String documentTypeLabel(String code) {
    for (final type in types) {
      if (type.$1 == code) return type.$2;
    }
    return 'Document';
  }
}

/// A file the provider picked but has not submitted yet.
class PendingVerificationDocument {
  final String type;
  final String fileName;
  final Uint8List bytes;

  const PendingVerificationDocument({required this.type, required this.fileName, required this.bytes});

  PendingVerificationDocument withType(String newType) =>
      PendingVerificationDocument(type: newType, fileName: fileName, bytes: bytes);

  bool get isPdf => fileName.toLowerCase().endsWith('.pdf');

  /// The API takes JPG, PNG and PDF up to 10 MB each.
  static const maxBytes = 10 * 1024 * 1024;
  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
}

DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;
