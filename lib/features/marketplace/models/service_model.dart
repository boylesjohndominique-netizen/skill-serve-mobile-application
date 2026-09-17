/// A public service from `GET /api/client/v1/services` or embedded in a
/// provider (`GET /api/client/v1/providers/{provider}`).
class ServiceModel {
  final String id;
  final String providerId;
  final String categoryId;
  final String categoryName;
  final String title;
  final String description;
  final double price;
  final String priceType; // fixed | hourly | custom
  final String duration;
  final String location;
  final String status;
  final String coverImage; // not provided by the API yet

  const ServiceModel({
    required this.id,
    required this.providerId,
    required this.categoryId,
    this.categoryName = '',
    required this.title,
    required this.description,
    required this.price,
    this.priceType = 'fixed',
    required this.duration,
    this.location = '',
    this.status = 'active',
    required this.coverImage,
  });

  /// [providerId] fills in the owner when the service is embedded in a
  /// provider payload, which omits the nested `provider` object.
  factory ServiceModel.fromJson(Map<String, dynamic> json, {String? providerId}) {
    final provider = json['provider'] as Map<String, dynamic>?;
    final category = json['category'] as Map<String, dynamic>?;

    return ServiceModel(
      id: json['id'].toString(),
      providerId: (provider?['id'] ?? json['provider_id'] ?? providerId ?? '').toString(),
      categoryId: (category?['id'] ?? json['category_id'] ?? '').toString(),
      categoryName: category?['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: double.tryParse('${json['price'] ?? 0}') ?? 0,
      priceType: json['price_type'] as String? ?? 'fixed',
      duration: json['duration'] as String? ?? '',
      location: json['location'] as String? ?? '',
      status: 'active',
      coverImage: json['cover_image'] as String? ?? '',
    );
  }
}
