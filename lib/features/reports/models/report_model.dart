/// Mirrors the `reports` table (complaints / disputes filed by a user).
enum ReportStatus { open, investigating, warned, suspended, closed }

/// One admin action on a report (drives the "timeline of admin actions").
class ReportUpdate {
  final String label;
  final DateTime at;
  final String status; // ReportStatus name for coloring

  const ReportUpdate({required this.label, required this.at, required this.status});
}

class ReportModel {
  final String id; // RP-1
  final String reporterName;
  final String reportedName;
  final String reason; // from the picklist in the spec
  final String details;
  final ReportStatus status;
  final DateTime createdAt;
  final List<ReportUpdate> updates;

  const ReportModel({
    required this.id,
    required this.reporterName,
    required this.reportedName,
    required this.reason,
    required this.details,
    required this.status,
    required this.createdAt,
    this.updates = const [],
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
        id: json['report_id'].toString(),
        reporterName: json['reporter_name'] as String? ?? '',
        reportedName: json['reported_name'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        details: json['details'] as String? ?? '',
        status: ReportStatus.values.byName(json['status'] as String? ?? 'open'),
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
        updates: (json['updates'] as List?)
                ?.map((e) => ReportUpdate(
                      label: e['label'] as String? ?? '',
                      at: DateTime.tryParse(e['at'] as String? ?? '') ?? DateTime.now(),
                      status: e['status'] as String? ?? 'open',
                    ))
                .toList() ??
            const [],
      );
}
