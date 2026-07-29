import '../data/mock/mock_data.dart';
import '../models/review_model.dart';
import 'api_client.dart';

/// Placeholder service for provider reviews.
class ReviewService {
  // GET /providers/:id/reviews
  Future<List<ReviewModel>> getReviewsForProvider(String providerId) async {
    await simulateNetworkDelay();
    return MockData.reviews;
  }

  // POST /bookings/:id/review
  Future<void> submitReview({required String bookingId, required double rating, required String comment}) async {
    await simulateNetworkDelay(ms: 500);
  }
}
