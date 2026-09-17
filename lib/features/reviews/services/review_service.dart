import '../models/review_model.dart';
import '../../../core/services/api_client.dart';

/// Service for provider reviews — live API only.
///
/// Endpoints:
/// - GET /api/client/v1/providers/{provider} (a provider's published reviews)
/// - POST /api/client/v1/reviews
/// - PATCH /api/client/v1/reviews/{review}
class ReviewService {
  // GET /api/client/v1/providers/{provider} — the public provider detail
  // carries its latest published reviews. (GET /api/client/v1/reviews lists
  // the signed-in customer's own reviews, not a provider's.)
  Future<List<ReviewModel>> getReviewsForProvider(String providerId) async {
    final response =
        await ApiClient.instance.dio.get('/client/v1/providers/$providerId');
    final reviews = (response.data['data'] as Map<String, dynamic>)['reviews'];
    return [
      for (final item in (reviews as List? ?? const []))
        ReviewModel.fromJson(item as Map<String, dynamic>),
    ];
  }

  // POST /api/client/v1/reviews
  Future<void> submitReview(
      {required String bookingId,
      required double rating,
      required String comment}) async {
    await ApiClient.instance.dio.post('/client/v1/reviews', data: {
      'booking_id': int.parse(bookingId),
      'rating': rating.round(),
      'comment': comment,
    });
  }
}
