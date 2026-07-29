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

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: json['review_id'].toString(),
        bookingId: json['booking_id'].toString(),
        clientName: json['client_name'] as String? ?? '',
        clientAvatar: json['client_avatar'] as String?,
        rating: (json['rating'] as num).toDouble(),
        comment: json['review'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
