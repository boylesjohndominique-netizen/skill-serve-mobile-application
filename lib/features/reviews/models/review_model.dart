/// Mirrors the `reviews` table.
class ReviewModel {
  final String id;
  final String bookingId;
  final String clientName;
  final String? clientAvatar;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.bookingId,
    required this.clientName,
    this.clientAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    final booking = json['booking'] as Map<String, dynamic>?;
    final reviewer = json['reviewer'] as Map<String, dynamic>?;

    return ReviewModel(
      id: (json['id'] ?? json['review_id']).toString(),
      bookingId: (booking?['id'] ?? json['booking_id'] ?? '').toString(),
      clientName: (reviewer?['name'] ?? json['client_name']) as String? ?? 'Customer',
      clientAvatar: json['client_avatar'] as String?,
      rating: double.tryParse('${json['rating'] ?? 0}') ?? 0,
      comment: (json['comment'] ?? json['review']) as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
