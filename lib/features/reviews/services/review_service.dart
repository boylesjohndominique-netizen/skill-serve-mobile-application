import '../models/review_model.dart';
import '../../../core/services/api_client.dart';

/// Service for reviews — live API only.
///
/// Endpoints (api-docs/modules/client-reviews.md):
/// - GET   /api/client/v1/providers/{provider}  (a provider's published reviews)
/// - GET   /api/client/v1/reviews               (the signed-in customer's own)
/// - POST  /api/client/v1/reviews
/// - PATCH /api/client/v1/reviews/{review}
class ReviewService {
  static const _base = '/client/v1/reviews';

  /// The public provider detail carries its latest published reviews.
  Future<List<ReviewModel>> getReviewsForProvider(String providerId) async {
    final response =
        await ApiClient.instance.dio.get('/client/v1/providers/$providerId');
    final reviews = (response.data['data'] as Map<String, dynamic>)['reviews'];
    return [
      for (final item in (reviews as List? ?? const []))
        ReviewModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// GET /api/client/v1/reviews — the reviews this customer has written.
  Future<List<ReviewModel>> getMyReviews() async {
    final response =
        await ApiClient.instance.dio.get(_base, queryParameters: {'per_page': 100});
    return [
      for (final item in response.data['data'] as List? ?? const [])
        ReviewModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  /// POST /api/client/v1/reviews — review a completed booking, once.
  Future<ReviewModel> submitReview({
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    final response = await ApiClient.instance.dio.post(_base, data: {
      'booking_id': int.parse(bookingId),
      'rating': rating.round(),
      if (comment.trim().isNotEmpty) 'comment': comment.trim(),
    });
    return ReviewModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// PATCH /api/client/v1/reviews/{review} — change a review already written.
  /// The API still requires the booking to be completed.
  Future<ReviewModel> updateReview({
    required String reviewId,
    required double rating,
    required String comment,
  }) async {
    final response = await ApiClient.instance.dio.patch('$_base/$reviewId', data: {
      'rating': rating.round(),
      // Sent even when empty, so clearing the text actually clears it.
      'comment': comment.trim(),
    });
    return ReviewModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
