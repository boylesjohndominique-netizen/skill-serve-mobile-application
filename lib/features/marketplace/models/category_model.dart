/// A service category from `GET /api/client/v1/categories`.
class CategoryModel {
  final String id;
  final String name;
  final String icon; // icon key resolved in the UI layer
  final int providerCount;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.providerCount = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    return CategoryModel(
      id: json['id'].toString(),
      name: name,
      icon: iconKeyFor(name),
      providerCount: (json['provider_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// The API has no category icons; pick one of the UI's icon keys from the
  /// category name, falling back to the generic work icon.
  static String iconKeyFor(String name) {
    final value = name.toLowerCase();
    const keywords = {
      'plumbing': ['plumb', 'pipe', 'water'],
      'bolt': ['electric', 'aircon', 'appliance', 'repair'],
      'school': ['tutor', 'school', 'lesson', 'education'],
      'brush': ['paint', 'clean', 'beauty', 'design'],
      'photo_camera': ['photo', 'video', 'camera', 'event'],
      'carpenter': ['carpent', 'wood', 'furniture', 'construction'],
    };
    for (final entry in keywords.entries) {
      if (entry.value.any(value.contains)) return entry.key;
    }
    return 'work';
  }
}
