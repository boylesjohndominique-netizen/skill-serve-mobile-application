import 'user_model.dart';

/// Mirrors the `providers` table, joined with its underlying [UserModel]
/// for display purposes.
class ProviderModel {
  final String id;
  final UserModel user;
  final String bio;
  final int yearsExperience;
  final String verificationStatus; // verified | pending | rejected
  final double averageRating;
  final int reviewCount;
  final int completedJobs;
  final String categoryName;
  final List<String> portfolioImages;
  final double? startingPrice;

  const ProviderModel({
    required this.id,
    required this.user,
    this.bio = '',
    this.yearsExperience = 0,
    this.verificationStatus = 'pending',
    this.averageRating = 0,
    this.reviewCount = 0,
    this.completedJobs = 0,
    required this.categoryName,
    this.portfolioImages = const [],
    this.startingPrice,
  });

  bool get isVerified => verificationStatus == 'verified';

  factory ProviderModel.fromJson(Map<String, dynamic> json) => ProviderModel(
        id: json['provider_id'].toString(),
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
        bio: json['bio'] as String? ?? '',
        yearsExperience: json['years_experience'] as int? ?? 0,
        verificationStatus: json['verification_status'] as String? ?? 'pending',
        averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0,
        reviewCount: json['review_count'] as int? ?? 0,
        completedJobs: json['completed_jobs'] as int? ?? 0,
        categoryName: json['category_name'] as String? ?? '',
        portfolioImages: (json['portfolio_images'] as List?)?.cast<String>() ?? const [],
        startingPrice: (json['starting_price'] as num?)?.toDouble(),
      );
}
