import '../models/review_model.dart';
import '../../../core/services/api_client.dart';

/// Service for provider reviews — live API only.
///
/// Endpoints:
/// - GET /api/client/v1/reviews
/// - POST /api/client/v1/reviews
/// - PATCH /api/client/v1/reviews/{review}
class ReviewService {
  // GET /api/client/v1/reviews
  Future<List<ReviewModel>> getReviewsForProvider(String providerId) async {
    final response =
        await ApiClient.instance.dio.get('/client/v1/reviews');
    final data = response.data['data'];
    final items = data is List
        ? data
        : data is Map<String, dynamic>
            ? data['data'] as List? ?? []
            : [];
    return items
        .map((json) => ReviewModel.fromJson(json as Map<String, dynamic>))
        .toList();
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
