import '../../provider/models/provider_availability_model.dart';
import 'category_model.dart';

/// How a result list is ordered. The values map onto the `sort`/`direction`
/// pair documented for `GET /api/client/v1/providers` and `/services`.
enum DiscoverySort {
  newest('Newest', 'created_at', 'desc'),
  topRated('Top rated', 'average_rating', 'desc'),
  priceLowToHigh('Price: low to high', 'price', 'asc'),
  nameAZ('Name: A–Z', 'business_name', 'asc');

  const DiscoverySort(this.label, this.field, this.direction);

  final String label;
  final String field;
  final String direction;

  /// `business_name` and `price` are accepted by one endpoint each, so the
  /// unsupported options are hidden from the matching filter sheet.
  bool get appliesToProviders => this != DiscoverySort.priceLowToHigh;

  bool get appliesToServices => this != DiscoverySort.nameAZ;
}

/// The discovery filters a client can apply to providers and services:
/// category, minimum rating, administrator recognition, and whether the
/// provider can be booked online right now.
///
/// Immutable so controllers can compare the applied set and rebuild only
/// when it actually changes.
class DiscoveryFilters {
  final CategoryModel? category;

  /// Lowest average rating a result may carry; `null` means any rating.
  final double? minRating;

  /// Only providers administrators have featured.
  final bool featuredOnly;

  /// Only providers taking new bookings who have a service that can be
  /// booked online.
  final bool availableOnly;

  /// Only providers publishing hours on this weekday (0 = Sunday), or
  /// `null` for any day.
  final int? availableDay;

  final DiscoverySort sort;

  const DiscoveryFilters({
    this.category,
    this.minRating,
    this.featuredOnly = false,
    this.availableOnly = false,
    this.availableDay,
    this.sort = DiscoverySort.newest,
  });

  /// Rating steps offered in the filter sheet.
  static const ratingOptions = <double>[3, 4, 4.5];

  /// "4+" / "4.5+" — how a rating threshold reads in the UI.
  static String ratingLabel(double rating) =>
      '${rating.truncateToDouble() == rating ? rating.toStringAsFixed(0) : rating.toStringAsFixed(1)}+';

  bool get isEmpty =>
      category == null &&
      minRating == null &&
      !featuredOnly &&
      !availableOnly &&
      availableDay == null &&
      sort == DiscoverySort.newest;

  /// "Saturday" for the applied day filter, empty when none is applied.
  String get availableDayLabel => availableDay == null
      ? ''
      : ProviderAvailabilityModel.dayNames[availableDay!.clamp(0, 6)];

  /// How many filters the user has applied — drives the badge on the filter
  /// button.
  int get activeCount => [
        category != null,
        minRating != null,
        featuredOnly,
        availableOnly,
        availableDay != null,
        sort != DiscoverySort.newest,
      ].where((applied) => applied).length;

  DiscoveryFilters copyWith({
    CategoryModel? category,
    bool clearCategory = false,
    double? minRating,
    bool clearMinRating = false,
    bool? featuredOnly,
    bool? availableOnly,
    int? availableDay,
    bool clearAvailableDay = false,
    DiscoverySort? sort,
  }) {
    return DiscoveryFilters(
      category: clearCategory ? null : (category ?? this.category),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      featuredOnly: featuredOnly ?? this.featuredOnly,
      availableOnly: availableOnly ?? this.availableOnly,
      availableDay: clearAvailableDay ? null : (availableDay ?? this.availableDay),
      sort: sort ?? this.sort,
    );
  }

  /// Query parameters for `GET /api/client/v1/providers`.
  Map<String, dynamic> toProviderQuery() => {
        if (category != null) 'category_id': category!.id,
        if (minRating != null) 'min_rating': minRating,
        if (featuredOnly) 'featured': 1,
        if (availableOnly) 'available': 1,
        if (availableDay != null) 'available_day': availableDay,
        if (sort.appliesToProviders) ...{
          'sort': sort.field,
          'direction': sort.direction,
        },
      };

  /// Query parameters for `GET /api/client/v1/services`. Recognition and
  /// availability are provider-only filters, so they are dropped here.
  Map<String, dynamic> toServiceQuery() => {
        if (category != null) 'category_id': category!.id,
        if (minRating != null) 'min_rating': minRating,
        if (sort.appliesToServices) ...{
          'sort': sort.field,
          'direction': sort.direction,
        },
      };

  @override
  bool operator ==(Object other) =>
      other is DiscoveryFilters &&
      other.category?.id == category?.id &&
      other.minRating == minRating &&
      other.featuredOnly == featuredOnly &&
      other.availableOnly == availableOnly &&
      other.availableDay == availableDay &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(
        category?.id,
        minRating,
        featuredOnly,
        availableOnly,
        availableDay,
        sort,
      );
}
