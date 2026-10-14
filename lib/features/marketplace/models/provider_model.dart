import '../../auth/models/user_model.dart';
import '../../reviews/models/review_model.dart';
import 'service_model.dart';
import '../../provider/models/badge_model.dart';
import '../../provider/models/portfolio_model.dart';
import '../../provider/models/provider_availability_model.dart';

/// A public provider from `GET /api/client/v1/providers` (list) or
/// `GET /api/client/v1/providers/{provider}` (detail, with services and reviews).
///
/// The public catalog only lists verified providers and never exposes the
/// provider's user account, so [user] is a display identity built from the
/// API's `display_name` — the business name, or the account holder's name when
/// the provider gave no business name — and their account photo.
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
  final int completedBookings;
  final String categoryName;

  /// The covers of [portfolio], for carousels and thumbnails.
  final List<String> portfolioImages;

  /// The provider's pieces of work with all their photos, on the detail
  /// payload.
  final List<PortfolioModel> portfolio;

  /// Skills the provider lists on their profile, shown on the public profile.
  final List<String> skills;

  /// Administrator-managed recognition: `is_featured` on the profile plus the
  /// badges awarded to the provider.
  final bool isFeatured;

  /// Recognition badges, present on the public provider detail payload.
  final List<BadgeModel> badges;

  /// Whether the provider is taking new bookings at all.
  final bool isAcceptingBookings;

  /// Working a job right now (a booking in progress). Informational: they
  /// can still be booked and messaged.
  final bool onJobNow;

  /// Published weekly hours, present on the provider detail payload. Empty
  /// means the provider publishes none, which does not restrict when they
  /// can be booked.
  final List<ProviderAvailabilityModel> availability;
  final double? startingPrice;
  final List<ServiceModel> services;
  final List<ReviewModel> reviews;

  /// Where a customer sends a GCash payment, and the name GCash will show
  /// them. Present only on the provider's own profile
  /// (`GET /api/client/v1/provider/profile`) — the public catalog never
  /// carries someone's personal payment details.
  final String? gcashNumber;
  final String? gcashName;

  /// The provider's GCash "Receive via QR" code as the QR Ph text it encodes;
  /// own profile only. Each GCash booking gets a copy with its exact amount.
  final String? gcashQrPayload;

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
    this.completedBookings = 0,
    required this.categoryName,
    this.portfolioImages = const [],
    this.portfolio = const [],
    this.skills = const [],
    this.isFeatured = false,
    this.badges = const [],
    this.isAcceptingBookings = true,
    this.onJobNow = false,
    this.availability = const [],
    this.startingPrice,
    this.services = const [],
    this.reviews = const [],
    this.gcashNumber,
    this.gcashName,
    this.gcashQrPayload,
  });

  /// Whether a customer choosing GCash can actually be told where to pay.
  bool get canReceiveGcash => (gcashNumber ?? '').isNotEmpty;

  bool get isVerified => verificationStatus == 'verified';

  /// Earned "Top Rated" recognition, awarded by administrators.
  bool get isTopRated =>
      badges.any((badge) => badge.earned && badge.key == 'top_rated');

  /// The recognition badges the provider actually holds.
  List<BadgeModel> get earnedBadges =>
      badges.where((badge) => badge.earned).toList();

  /// Shown when a payload names the provider nowhere at all.
  static const fallbackName = 'SkillServe provider';

  /// What to call a provider in a catalog payload: `display_name` from the
  /// API, else the business name, else [fallbackName] — never a blank.
  static String nameFrom(Map<String, dynamic> json) {
    for (final key in const ['display_name', 'business_name']) {
      final value = (json[key] as String? ?? '').trim();
      if (value.isNotEmpty) return value;
    }
    return fallbackName;
  }

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'].toString();
    final displayName = nameFrom(json);
    final photoUrl = json['profile_photo_url'] as String?;
    final services = [
      for (final item in (json['services'] as List? ?? const []))
        ServiceModel.fromJson(item as Map<String, dynamic>, providerId: id, providerName: displayName),
    ];
    final prices = services.map((s) => s.price);

    return ProviderModel(
      id: id,
      user: UserModel(
        id: 'provider-$id',
        role: UserRole.provider,
        firstName: displayName,
        lastName: '',
        email: '',
        profilePicture: photoUrl == null || photoUrl.isEmpty ? null : photoUrl,
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
      completedBookings: (json['completed_bookings'] as num?)?.toInt() ?? 0,
      categoryName: (json['primary_category'] as String?) ??
          (services.isNotEmpty ? services.first.categoryName : null) ??
          (json['specialization'] as String? ?? ''),
      portfolioImages: _imageUrls(json['portfolio']),
      portfolio: [
        for (final item in (json['portfolio'] as List? ?? const []))
          if (item is Map && item['portfolio_id'] != null)
            PortfolioModel.fromJson(item.cast<String, dynamic>()),
      ],
      skills: _strings(json['skills']),
      isFeatured: json['is_featured'] == true,
      badges: [
        for (final item in (json['badges'] as List? ?? const []))
          BadgeModel.fromJson(item as Map<String, dynamic>),
      ],
      // Absent on older payloads; a provider is bookable unless they say
      // otherwise.
      isAcceptingBookings: json['is_accepting_bookings'] != false,
      onJobNow: json['on_job_now'] == true,
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
      gcashNumber: json['gcash_number'] as String?,
      gcashName: json['gcash_name'] as String?,
      gcashQrPayload: json['gcash_qr_payload'] as String?,
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
