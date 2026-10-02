/// A place from the PSA's Philippine Standard Geographic Code, as
/// `GET /api/client/v1/locations/*` returns it (api-docs/modules/locations.md).
class PhPlace {
  /// The 9-digit PSGC code. Places are told apart by code, never by name:
  /// "San Jose" is a municipality in nine provinces.
  final String code;
  final String name;

  /// `region`, `province`, `city`, `municipality` or `barangay`. A region's
  /// children mix provinces with cities that have none (all of NCR).
  final String level;
  final String? parentCode;

  const PhPlace({required this.code, required this.name, this.level = '', this.parentCode});

  bool get isProvince => level == 'province';
  bool get isLocality => level == 'city' || level == 'municipality';

  factory PhPlace.fromJson(Map<String, dynamic> json) => PhPlace(
        code: '${json['code']}',
        name: json['name'] as String? ?? '',
        level: json['level'] as String? ?? '',
        parentCode: json['parent_code'] as String?,
      );

  static PhPlace? maybe(Object? json) =>
      json is Map ? PhPlace.fromJson(Map<String, dynamic>.from(json)) : null;

  @override
  bool operator ==(Object other) => other is PhPlace && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

/// An address picked as Region → Province → City/Municipality → Barangay,
/// plus street and ZIP.
///
/// The API is sent only the most specific place — the barangay for a door
/// address, the city for a service area — and derives the rest, so the
/// levels above are kept here only to show and re-open the picker.
class PhAddress {
  final PhPlace? region;

  /// Null for a city without a province (all of NCR).
  final PhPlace? province;
  final PhPlace? city;
  final PhPlace? barangay;
  final String street;
  final String postalCode;

  const PhAddress({
    this.region,
    this.province,
    this.city,
    this.barangay,
    this.street = '',
    this.postalCode = '',
  });

  static const empty = PhAddress();

  /// Complete enough for a door address: a barangay is chosen.
  bool get hasBarangay => barangay != null;

  /// Complete enough for a service area: a city or municipality is chosen.
  bool get hasCity => city != null;

  /// `{barangay_code, street, postal_code}` for `address_details` and
  /// `service_address_details`.
  Map<String, dynamic> toDoorJson() => {
        'barangay_code': barangay!.code,
        if (street.trim().isNotEmpty) 'street': street.trim(),
        if (postalCode.trim().isNotEmpty) 'postal_code': postalCode.trim(),
      };

  /// `{city_code, barangay_code?}` for a service's `location_details`.
  Map<String, dynamic> toAreaJson() => {
        'city_code': city!.code,
        if (barangay != null) 'barangay_code': barangay!.code,
      };

  /// "123 Rizal St, Bagong Pag-asa, Quezon City, Metro Manila 1105" — the
  /// same text the API stores, for showing before it is saved.
  String get formatted {
    final area = province?.name ?? (region?.code == '130000000' ? 'Metro Manila' : region?.name);
    final text = [street.trim(), barangay?.name, city?.name, area]
        .where((part) => part != null && part.isNotEmpty)
        .join(', ');
    return postalCode.trim().isEmpty ? text : '$text ${postalCode.trim()}';
  }

  /// A stored address (`address_details`, `service_address_details` or
  /// `location_details`), or null when only free text was ever entered.
  static PhAddress? fromJson(Object? json) {
    if (json is! Map) return null;
    final map = Map<String, dynamic>.from(json);
    return PhAddress(
      region: PhPlace.maybe(map['region']),
      province: PhPlace.maybe(map['province']),
      city: PhPlace.maybe(map['city']),
      barangay: PhPlace.maybe(map['barangay']),
      street: map['street'] as String? ?? '',
      postalCode: map['postal_code'] as String? ?? '',
    );
  }

  /// The same shape [fromJson] reads, for caching a stored address.
  Map<String, dynamic> toJson() {
    Map<String, String>? place(PhPlace? p) => p == null ? null : {'code': p.code, 'name': p.name};
    return {
      'region': place(region),
      'province': place(province),
      'city': place(city),
      'barangay': place(barangay),
      'street': street.isEmpty ? null : street,
      'postal_code': postalCode.isEmpty ? null : postalCode,
    };
  }

  PhAddress copyWith({String? street, String? postalCode}) => PhAddress(
        region: region,
        province: province,
        city: city,
        barangay: barangay,
        street: street ?? this.street,
        postalCode: postalCode ?? this.postalCode,
      );
}
