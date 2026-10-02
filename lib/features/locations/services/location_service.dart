import 'package:dio/dio.dart';

import '../../../core/services/api_client.dart';
import '../models/ph_address.dart';

/// The Philippine address picker's data (api-docs/modules/locations.md):
/// - GET /api/client/v1/locations/regions
/// - GET /api/client/v1/locations/{code}/children
/// - GET /api/client/v1/locations/match?address=
///
/// Public: sign-up uses it before an account exists. Lists never change
/// while the app runs, so each is fetched once and kept.
class LocationService {
  LocationService({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;
  static const _path = '/client/v1/locations';
  static final Map<String, List<PhPlace>> _cache = {};

  Future<List<PhPlace>> regions() => _list('$_path/regions');

  /// The places one level below [code]. For a region that is its provinces
  /// plus any city without one; for a province its cities/municipalities;
  /// for a city or municipality its barangays.
  Future<List<PhPlace>> children(String code) => _list('$_path/$code/children');

  /// The picker selections for an address printed on a National ID. Levels
  /// the server could not decide are left empty for the user to pick, and
  /// the part before them comes back as the street.
  Future<PhAddress> match(String address) async {
    final response = await _dio.get('$_path/match', queryParameters: {'address': address});
    final data = Map<String, dynamic>.from(response.data['data'] as Map);
    return PhAddress(
      region: PhPlace.maybe(data['region']),
      province: PhPlace.maybe(data['province']),
      city: PhPlace.maybe(data['city']),
      barangay: PhPlace.maybe(data['barangay']),
      street: data['street'] as String? ?? '',
    );
  }

  Future<List<PhPlace>> _list(String path) async {
    final cached = _cache[path];
    if (cached != null) return cached;
    final response = await _dio.get(path);
    final places = [
      for (final item in response.data['data'] as List) PhPlace.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
    return _cache[path] = places;
  }

  /// For tests: forget what was fetched.
  static void clearCache() => _cache.clear();
}
