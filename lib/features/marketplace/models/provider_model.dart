import '../../auth/models/user_model.dart';
import '../../reviews/models/review_model.dart';
import 'service_model.dart';
import '../../provider/models/badge_model.dart';
import '../../provider/models/provider_availability_model.dart';

/// A public provider from `GET /api/client/v1/providers` (list) or
/// `GET /api/client/v1/providers/{provider}` (detail, with services and reviews).
///
/// The public catalog only lists verified providers and never exposes the
/// provider's user account, so [user] is a display identity built from the
/// business name.
class ProviderModel {
  final String id;
  final UserModel user;
  final String bio;
  final String location;
  final int yearsExperience;
  final String verificationStatus; // verified | pending | rejected
  final DateTime? verifiedAt;
  final double averageRating;
  final int reviewCount;
  final int completedJobs;
  final String categoryName;
  final List<String> portfolioImages;

  /// Skills the provider lists on their profile, shown on the public profile.
  final List<String> skills;

  /// Administrator-managed recognition: `is_featured` on the profile plus the
  /// badges awarded to the provider.
  final bool isFeatured;

  /// Recognition badges, present on the public provider detail payload.
  final List<BadgeModel> badges;

  /// Whether the provider is taking new bookings at all.
  final bool isAcceptingBookings;

  /// Published weekly hours, present on the provider detail payload. Empty
  /// means the provider publishes none, which does not restrict when they
  /// can be booked.
  final List<ProviderAvailabilityModel> availability;
  final double? startingPrice;
  final List<ServiceModel> services;
  final List<ReviewModel> reviews;

  const ProviderModel({
    required this.id,
    required this.user,
    this.bio = '',
    this.location = '',
    this.yearsExperience = 0,
    this.verificationStatus = 'pending',
    this.verifiedAt,
    this.averageRating = 0,
    this.reviewCount = 0,
    this.completedJobs = 0,
    required this.categoryName,
    this.portfolioImages = const [],
    this.skills = const [],
    this.isFeatured = false,
    this.badges = const [],
    this.isAcceptingBookings = true,
    this.availability = const [],
    this.startingPrice,
    this.services = const [],
    this.reviews = const [],
  });

  bool get isVerified => verificationStatus == 'verified';

  /// Earned "Top Rated" recognition, awarded by administrators.
  bool get isTopRated =>
      badges.any((badge) => badge.earned && badge.key == 'top_rated');

  /// The recognition badges the provider actually holds.
  List<BadgeModel> get earnedBadges =>
      badges.where((badge) => badge.earned).toList();

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final businessName = json['business_name'] as String? ?? '';
    final services = [
      for (final item in (json['services'] as List? ?? const []))
        ServiceModel.fromJson(item as Map<String, dynamic>, providerId: id, providerName: businessName),
    ];
    final prices = services.map((s) => s.price);

    return ProviderModel(
      id: id,
      user: UserModel(
        id: 'provider-$id',
        role: UserRole.provider,
        firstName: businessName,
        lastName: '',
        email: '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      ),
      bio: (json['bio'] ?? json['specialization']) as String? ?? '',
      location: json['location'] as String? ?? '',
      yearsExperience: int.tryParse('${json['experience_years'] ?? 0}') ?? 0,
      // Only verified providers are exposed by the public catalog, but the
      // payload states the status so the profile can show it.
      verificationStatus: json['verification_status'] as String? ?? 'verified',
      verifiedAt: DateTime.tryParse(json['verified_at'] as String? ?? ''),
      averageRating: double.tryParse('${json['average_rating'] ?? 0}') ?? 0,
      reviewCount: (json['total_reviews'] as num?)?.toInt() ?? 0,
      completedJobs: (json['completed_bookings'] as num?)?.toInt() ?? 0,
      categoryName: (json['primary_category'] as String?) ??
          (services.isNotEmpty ? services.first.categoryName : null) ??
          (json['specialization'] as String? ?? ''),
      portfolioImages: _imageUrls(json['portfolio']),
      skills: _strings(json['skills']),
      isFeatured: json['is_featured'] == true,
      badges: [
        for (final item in (json['badges'] as List? ?? const []))
          BadgeModel.fromJson(item as Map<String, dynamic>),
      ],
      // Absent on older payloads; a provider is bookable unless they say
      // otherwise.
      isAcceptingBookings: json['is_accepting_bookings'] != false,
      availability: [
        for (final item in (json['availability'] as List? ?? const []))
          ProviderAvailabilityModel.fromJson(item as Map<String, dynamic>),
      ],
      startingPrice: double.tryParse('${json['starting_price']}') ??
          (prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b)),
      services: services,
      reviews: [
        for (final item in (json['reviews'] as List? ?? const []))
          ReviewModel.fromJson(item as Map<String, dynamic>),
      ],
    );
  }

  /// Portfolio entries may be plain URLs or objects carrying a URL.
  static List<String> _imageUrls(Object? portfolio) {
    if (portfolio is! List) return const [];
    return [
      for (final item in portfolio)
        if (item is String && item.startsWith('http'))
          item
        else if (item is Map && (item['url'] ?? item['image'] ?? item['image_url']) is String)
          (item['url'] ?? item['image'] ?? item['image_url']) as String,
    ];
  }

  /// `skills`, `certifications` and `languages` are free-form JSON arrays on
  /// the provider profile; keep only the non-empty text entries.
  static List<String> _strings(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item != null && '$item'.trim().isNotEmpty) '$item'.trim(),
    ];
  }
}
