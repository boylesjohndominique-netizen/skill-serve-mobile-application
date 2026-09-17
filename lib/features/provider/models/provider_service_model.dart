/// A provider's own service as returned by
/// `GET /api/client/v1/provider/services`, including its moderation state.
class ProviderServiceModel {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String categoryName;
  final String? subcategoryId;
  final String? subcategoryName;
  final double price;
  final String priceType; // fixed | hourly | custom
  final String duration;
  final String location;
  final String status; // draft | published | archived
  final String approvalStatus; // pending | approved | rejected
  final String? rejectionReason;
  final bool isHidden;
  final bool isFeatured;

  const ProviderServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.categoryName,
    this.subcategoryId,
    this.subcategoryName,
    required this.price,
    required this.priceType,
    required this.duration,
    required this.location,
    required this.status,
    required this.approvalStatus,
    this.rejectionReason,
    this.isHidden = false,
    this.isFeatured = false,
  });

  bool get isPending => approvalStatus == 'pending';
  bool get isApproved => approvalStatus == 'approved';
  bool get isRejected => approvalStatus == 'rejected';

  /// Visible in the customer catalog only when approved, published and not hidden.
  bool get isLive => isApproved && status == 'published' && !isHidden;

  factory ProviderServiceModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final subcategory = json['subcategory'] as Map<String, dynamic>?;

    return ProviderServiceModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryId: (json['category_id'] ?? category?['id'] ?? '').toString(),
      categoryName: category?['name'] as String? ?? '',
      subcategoryId: (json['subcategory_id'] ?? subcategory?['id'])?.toString(),
      subcategoryName: subcategory?['name'] as String?,
      price: double.tryParse('${json['price'] ?? 0}') ?? 0,
      priceType: json['price_type'] as String? ?? 'fixed',
      duration: json['duration'] as String? ?? '',
      location: json['location'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      approvalStatus: json['approval_status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      isHidden: json['is_hidden'] == true,
      isFeatured: json['is_featured'] == true,
    );
  }
}

/// An enabled category (with its enabled subcategories) a provider can list under.
class ServiceCategoryOption {
  final String id;
  final String name;
  final List<ServiceSubcategoryOption> subcategories;

  const ServiceCategoryOption({required this.id, required this.name, this.subcategories = const []});

  factory ServiceCategoryOption.fromJson(Map<String, dynamic> json) => ServiceCategoryOption(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        subcategories: [
          for (final item in (json['subcategories'] as List? ?? const []))
            ServiceSubcategoryOption.fromJson(item as Map<String, dynamic>),
        ],
      );
}

class ServiceSubcategoryOption {
  final String id;
  final String name;

  const ServiceSubcategoryOption({required this.id, required this.name});

  factory ServiceSubcategoryOption.fromJson(Map<String, dynamic> json) =>
      ServiceSubcategoryOption(id: json['id'].toString(), name: json['name'] as String? ?? '');
}
