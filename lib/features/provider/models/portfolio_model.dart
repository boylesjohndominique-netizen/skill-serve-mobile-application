/// One piece of work from `provider_portfolio_items`, as the API returns it:
/// a title, a description and up to [maxPhotos] photos, cover first.
class PortfolioModel {
  /// Photos one item may hold (the API's limit).
  static const maxPhotos = 10;

  final String id;
  final String providerId;

  /// The cover (first photo); older payloads carry only this.
  final String image;
  final String title;
  final String description;
  final List<PortfolioPhoto> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PortfolioModel({
    required this.id,
    required this.providerId,
    required this.image,
    required this.title,
    this.description = '',
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Every photo's URL, cover first — the cover alone when the payload
  /// predates albums.
  List<String> get photoUrls => images.isNotEmpty
      ? [for (final photo in images) photo.url]
      : (image.isEmpty ? const [] : [image]);

  int get photoCount => photoUrls.length;

  factory PortfolioModel.fromJson(Map<String, dynamic> json) => PortfolioModel(
        id: json['portfolio_id'].toString(),
        providerId: json['provider_id'].toString(),
        image: json['image'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        images: [
          for (final item in (json['images'] as List? ?? const []))
            if (item is Map && item['url'] is String)
              PortfolioPhoto(id: '${item['id']}', url: item['url'] as String),
        ],
        createdAt: DateTime.tryParse('${json['created_at'] ?? ''}')?.toLocal(),
        updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}')?.toLocal(),
      );
}

/// One photo of a portfolio item.
class PortfolioPhoto {
  final String id;
  final String url;
  const PortfolioPhoto({required this.id, required this.url});
}
