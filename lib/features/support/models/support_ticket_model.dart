/// Where a support ticket has got to. Mirrors the API's `status`.
enum TicketStatus { open, inProgress, resolved }

/// What a ticket is about. The value is what the API stores; the label is what
/// the form shows.
enum TicketCategory {
  general('general', 'General question'),
  booking('booking', 'A booking'),
  payment('payment', 'Payments'),
  account('account', 'My account'),
  technical('technical', 'Something is broken'),
  other('other', 'Something else');

  const TicketCategory(this.value, this.label);

  final String value;
  final String label;

  static String labelFor(String? value) {
    for (final category in TicketCategory.values) {
      if (category.value == value) return category.label;
    }
    return value == null || value.isEmpty ? 'General question' : value;
  }
}

/// One message on a support ticket — from the requester or from staff.
class TicketReply {
  final String id;
  final String body;
  final String authorName;
  final String authorId;
  final DateTime createdAt;

  const TicketReply({
    required this.id,
    required this.body,
    this.authorName = '',
    this.authorId = '',
    required this.createdAt,
  });

  factory TicketReply.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    return TicketReply(
      id: json['id'].toString(),
      body: json['body'] as String? ?? '',
      authorName: author?['name'] as String? ?? '',
      authorId: author?['id']?.toString() ?? '',
      createdAt: SupportTicketModel.parseDate(json['created_at']) ?? DateTime.now(),
    );
  }
}

/// A support ticket, as `ClientSupportTicket` returns it.
class SupportTicketModel {
  final String id;
  final String ticketNumber;
  final String subject;
  final String description;
  final String category;
  final String priority;
  final TicketStatus status;

  /// What support concluded when they closed the ticket.
  final String? resolutionNote;

  /// The conversation. Only loaded on the detail endpoint, so a list row shows
  /// an empty thread rather than a wrong count.
  final List<TicketReply> replies;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SupportTicketModel({
    required this.id,
    this.ticketNumber = '',
    required this.subject,
    this.description = '',
    this.category = 'general',
    this.priority = 'normal',
    required this.status,
    this.resolutionNote,
    this.replies = const [],
    required this.createdAt,
    this.updatedAt,
  });

  String get categoryLabel => TicketCategory.labelFor(category);

  /// A resolved ticket takes no further replies — the API refuses them.
  bool get isOpen => status != TicketStatus.resolved;

  factory SupportTicketModel.fromJson(Map<String, dynamic> json) => SupportTicketModel(
        id: json['id'].toString(),
        ticketNumber: json['ticket_number'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'general',
        priority: json['priority'] as String? ?? 'normal',
        status: statusFromApi(json['status'] as String?),
        resolutionNote: json['resolution_note'] as String?,
        replies: [
          for (final item in (json['messages'] as List? ?? const []))
            TicketReply.fromJson(item as Map<String, dynamic>),
        ],
        createdAt: parseDate(json['created_at']) ?? DateTime.now(),
        updatedAt: parseDate(json['updated_at']),
      );

  /// An unknown status reads as open rather than crashing the list.
  static TicketStatus statusFromApi(String? status) => switch (status) {
        'in_progress' => TicketStatus.inProgress,
        'resolved' => TicketStatus.resolved,
        _ => TicketStatus.open,
      };

  /// The API's value for a status, for filtering.
  static String statusToApi(TicketStatus status) =>
      status == TicketStatus.inProgress ? 'in_progress' : status.name;

  static DateTime? parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
