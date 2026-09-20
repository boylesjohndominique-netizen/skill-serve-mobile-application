/// A public service from `GET /api/client/v1/services` or embedded in a
/// provider (`GET /api/client/v1/providers/{provider}`).
class ServiceModel {
  final String id;
  final String providerId;
  final String providerName;
  final String categoryId;
  final String categoryName;
  final String title;
  final String description;
  final double price;
  final String priceType; // fixed | hourly | custom
  final String duration;
  final String location;
  final String status;
  final double averageRating;
  final int reviewCount;
  final String coverImage; // not provided by the API yet

  const ServiceModel({
    required this.id,
    required this.providerId,
    this.providerName = '',
    required this.categoryId,
    this.categoryName = '',
    required this.title,
    required this.description,
    required this.price,
    this.priceType = 'fixed',
    required this.duration,
    this.location = '',
    this.status = 'active',
    this.averageRating = 0,
    this.reviewCount = 0,
    required this.coverImage,
  });

  /// A custom-priced service is quoted by the provider, so it carries no
  /// bookable amount.
  bool get isQuoteOnly => priceType == 'custom' || price <= 0;

  /// [providerId] fills in the owner when the service is embedded in a
  /// provider payload, which omits the nested `provider` object.
  factory ServiceModel.fromJson(Map<String, dynamic> json, {String? providerId, String? providerName}) {
    final provider = json['provider'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;

    return ServiceModel(
      id: json['id'].toString(),
      providerId: (provider?['id'] ?? json['provider_id'] ?? providerId ?? '').toString(),
      providerName: provider?['business_name'] as String? ?? providerName ?? '',
      categoryId: (category?['id'] ?? json['category_id'] ?? '').toString(),
      categoryName: category?['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: double.tryParse('${json['price'] ?? 0}') ?? 0,
      priceType: json['price_type'] as String? ?? 'fixed',
      duration: json['duration'] as String? ?? '',
      location: json['location'] as String? ?? '',
      status: 'active',
      averageRating: double.tryParse('${json['average_rating'] ?? 0}') ?? 0,
      reviewCount: (json['total_reviews'] as num?)?.toInt() ?? 0,
      coverImage: json['cover_image'] as String? ?? '',
    );
  }
}
