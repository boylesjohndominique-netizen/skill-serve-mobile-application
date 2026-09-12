/// Mirrors the `categories` table.
class CategoryModel {
  final String id;
  final String name;
  final String icon; // Material icon name key, resolved in the UI layer
  final int providerCount;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.providerCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json['category_id'].toString(),
        name: json['category_name'] as String,
        icon: json['icon'] as String? ?? 'work',
        providerCount: json['provider_count'] as int? ?? 0,
      );
}
