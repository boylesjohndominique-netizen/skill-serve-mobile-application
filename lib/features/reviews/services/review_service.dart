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

  /// GET /api/client/v1/services/{service}/reviews — one page of a public
  /// service's published reviews, newest first, with its rating summary.
  /// [rating] narrows the page to one star rating; the summary always
  /// covers every review.
  Future<ServiceReviewsPage> getServiceReviews(
    String serviceId, {
    int page = 1,
    int perPage = 10,
    int? rating,
  }) async {
    final response = await ApiClient.instance.dio.get(
      '/client/v1/services/$serviceId/reviews',
      queryParameters: {'page': page, 'per_page': perPage, if (rating != null) 'rating': rating},
    );
    return ServiceReviewsPage.fromJson(response.data as Map<String, dynamic>);
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

/// One page of a service's reviews and the summary of all of them.
class ServiceReviewsPage {
  final List<ReviewModel> reviews;
  final double average;
  final int total;

  /// Reviews per star, 5 down to 1.
  final Map<int, int> breakdown;
  final int currentPage;
  final int lastPage;

  const ServiceReviewsPage({
    required this.reviews,
    required this.average,
    required this.total,
    required this.breakdown,
    required this.currentPage,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;

  factory ServiceReviewsPage.fromJson(Map<String, dynamic> body) {
    final meta = (body['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    final rating = (meta['rating'] as Map?)?.cast<String, dynamic>() ?? const {};
    final pagination = (meta['pagination'] as Map?)?.cast<String, dynamic>() ?? const {};
    final breakdown = (rating['breakdown'] as Map?) ?? const {};

    return ServiceReviewsPage(
      reviews: [
        for (final item in (body['data'] as List? ?? const []))
          ReviewModel.fromJson(item as Map<String, dynamic>),
      ],
      average: double.tryParse('${rating['average'] ?? 0}') ?? 0,
      total: (rating['total'] as num?)?.toInt() ?? 0,
      breakdown: {
        for (final e in breakdown.entries)
          if (int.tryParse('${e.key}') != null) int.parse('${e.key}'): (e.value as num?)?.toInt() ?? 0,
      },
      currentPage: (pagination['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (pagination['last_page'] as num?)?.toInt() ?? 1,
    );
  }
}
