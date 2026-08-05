/// Mirrors the `verification_documents` table — provider ID / certificate /
/// document submissions reviewed by admins.
class VerificationDocumentModel {
  final String id; // VD-1
  final String providerId;
  final String type; // ID | Certificate | Document
  final String label;
  final String status; // pending | approved | rejected | resubmission_requested
  final DateTime submittedAt;

  const VerificationDocumentModel({
    required this.id,
    required this.providerId,
    required this.type,
    required this.label,
    required this.status,
    required this.submittedAt,
  });

  factory VerificationDocumentModel.fromJson(Map<String, dynamic> json) =>
      VerificationDocumentModel(
        id: json['document_id'].toString(),
        providerId: json['provider_id'].toString(),
        type: json['type'] as String? ?? 'Document',
        label: json['label'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        submittedAt:
            DateTime.tryParse(json['submitted_at'] as String? ?? '') ??
                DateTime.now(),
      );
}
