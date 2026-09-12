/// Mirrors the `services` table.
class ServiceModel {
  final String id;
  final String providerId;
  final String categoryId;
  final String title;
  final String description;
  final double price;
  final String duration;
  final String status; // active | paused
  final String coverImage;

  const ServiceModel({
    required this.id,
    required this.providerId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    this.status = 'active',
    required this.coverImage,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['service_id'].toString(),
        providerId: json['provider_id'].toString(),
        categoryId: json['category_id'].toString(),
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        price: (json['price'] as num).toDouble(),
        duration: json['duration'] as String? ?? '',
        status: json['status'] as String? ?? 'active',
        coverImage: json['cover_image'] as String? ?? '',
      );
}
