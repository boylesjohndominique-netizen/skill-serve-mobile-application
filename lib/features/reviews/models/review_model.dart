/// A review, as `ClientReview` returns it.
///
/// Serves both directions: a provider's published reviews (where the reviewer's
/// name is what matters) and the signed-in customer's own review history (where
/// the service and provider are).
class ReviewModel {
  final String id;
  final String bookingId;
  final String bookingNumber;
  final String reviewerId;
  final String clientName;
  final String? clientAvatar;
  final double rating;
  final String comment;

  /// What the review is about — filled on the customer's own review list.
  final String serviceTitle;
  final String providerName;

  /// Moderation state: `active` (published), `hidden` or `removed`. A hidden
  /// review is still the author's, so they are told rather than left guessing.
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReviewModel({
    required this.id,
    required this.bookingId,
    this.bookingNumber = '',
    this.reviewerId = '',
    required this.clientName,
    this.clientAvatar,
    required this.rating,
    required this.comment,
    this.serviceTitle = '',
    this.providerName = '',
    this.status = 'active',
    required this.createdAt,
    this.updatedAt,
  });

  /// The API calls a published review `active`.
  bool get isPublished => status == 'active';

  /// True once the author has changed it, so the list can say "edited".
  bool get wasEdited =>
      updatedAt != null && updatedAt!.difference(createdAt).inSeconds.abs() > 1;

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] as Map<String, dynamic>?;
    final reviewer = json['reviewer'] as Map<String, dynamic>?;
    final service = json['service'] as Map<String, dynamic>?;
    final provider = json['provider'] as Map<String, dynamic>?;

    return ReviewModel(
      id: (json['id'] ?? json['review_id']).toString(),
      bookingId: (booking?['id'] ?? json['booking_id'] ?? '').toString(),
      bookingNumber: booking?['booking_number'] as String? ?? '',
      reviewerId: reviewer?['id']?.toString() ?? '',
      clientName: (reviewer?['name'] ?? json['client_name']) as String? ?? 'Customer',
      clientAvatar: json['client_avatar'] as String?,
      rating: double.tryParse('${json['rating'] ?? 0}') ?? 0,
      comment: (json['comment'] ?? json['review']) as String? ?? '',
      serviceTitle: service?['title'] as String? ?? '',
      providerName: provider?['business_name'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      createdAt: _date(json['created_at']) ?? DateTime.now(),
      updatedAt: _date(json['updated_at']),
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
