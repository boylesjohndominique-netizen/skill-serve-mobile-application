import 'package:flutter/foundation.dart';
import '../../../core/utils/api_error.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

/// State for the customer's own review history, and for writing or editing one.
class ReviewController extends ChangeNotifier {
  final ReviewService _service = ReviewService();

  List<ReviewModel> myReviews = [];
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  Future<void> loadMyReviews() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      myReviews = await _service.getMyReviews();
    } catch (e) {
      myReviews = [];
      errorMessage = apiErrorMessage(e, 'Unable to load your reviews.');
    }
    isLoading = false;
    notifyListeners();
  }

  /// The review this account already left on [bookingId], if any — what tells
  /// the write screen whether it is creating or editing.
  ReviewModel? reviewForBooking(String bookingId) {
    for (final review in myReviews) {
      if (review.bookingId == bookingId) return review;
    }
    return null;
  }

  /// Posts a new review. Returns null and sets [errorMessage] when the API
  /// refuses — most often because the booking is not completed, or already
  /// reviewed.
  Future<ReviewModel?> submit({
    required String bookingId,
    required double rating,
    required String comment,
  }) {
    return _save(() => _service.submitReview(
          bookingId: bookingId,
          rating: rating,
          comment: comment,
        ), 'Unable to post your review.');
  }

  /// Changes a review already written.
  Future<ReviewModel?> update({
    required String reviewId,
    required double rating,
    required String comment,
  }) {
    return _save(() => _service.updateReview(
          reviewId: reviewId,
          rating: rating,
          comment: comment,
        ), 'Unable to save your changes.');
  }

  Future<ReviewModel?> _save(
    Future<ReviewModel> Function() action,
    String fallback,
  ) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final saved = await action();
      final index = myReviews.indexWhere((r) => r.id == saved.id);
      myReviews = index == -1
          ? [saved, ...myReviews]
          : ([...myReviews]..[index] = saved);
      return saved;
    } catch (e) {
      errorMessage = apiErrorMessage(e, fallback);
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
