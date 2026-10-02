import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skilllink_mobile/core/services/api_client.dart';
import 'package:skilllink_mobile/core/theme/app_theme.dart';
import 'package:skilllink_mobile/features/auth/models/user_model.dart';
import 'package:skilllink_mobile/features/booking/services/booking_service.dart';
import 'package:skilllink_mobile/features/locations/models/ph_address.dart';
import 'package:skilllink_mobile/features/locations/services/location_service.dart';
import 'package:skilllink_mobile/features/locations/widgets/ph_address_picker.dart';
import 'package:skilllink_mobile/features/profile/services/profile_service.dart';
import 'package:skilllink_mobile/features/provider/models/provider_service_model.dart';

Map<String, dynamic> _place(String code, String name, String level, [String? parent]) =>
    {'code': code, 'name': name, 'level': level, 'parent_code': parent};

/// A slice of the real PSGC (real codes): NCR, whose cities have no
/// province, and CALABARZON → Laguna → Santa Rosa.
final _children = <String, List<Map<String, dynamic>>>{
  'regions': [
    _place('130000000', 'National Capital Region (NCR)', 'region'),
    _place('040000000', 'Region IV-A (CALABARZON)', 'region'),
  ],
  '130000000': [_place('137404000', 'Quezon City', 'city', '130000000')],
  '040000000': [_place('043400000', 'Laguna', 'province', '040000000')],
  '043400000': [_place('043428000', 'City of Santa Rosa', 'city', '043400000')],
  '137404000': [_place('137404009', 'Bagong Pag-asa', 'barangay', '137404000')],
  '043428000': [_place('043428002', 'Balibago', 'barangay', '043428000')],
};

/// Answers the location endpoints from [_children], and records any other
/// request (profile, booking) so its body can be checked.
class _FakeApi implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final match = RegExp(r'/locations/(regions|(\d{9})/children)$').firstMatch(options.path);
    final Object data = match != null
        ? _children[match.group(2) ?? 'regions']!
        : options.path.endsWith('/auth/me')
            ? {'id': 1, 'first_name': 'Juan', 'last_name': 'Dela Cruz', 'email': 'juan@example.com', 'role_id': 4, 'address': 'Bagong Pag-asa, Quezon City, Metro Manila'}
            : {'id': 9, 'status': 'pending'};
    return ResponseBody.fromString(jsonEncode({'success': true, 'data': data}), 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _choose(WidgetTester tester, String level, String place) async {
  await tester.ensureVisible(find.text(level));
  await tester.tap(find.text(level));
  await tester.pumpAndSettle();
  await tester.tap(find.text(place).last);
  await tester.pumpAndSettle();
}

void main() {
  late _FakeApi api;
  late HttpClientAdapter original;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocationService.clearCache();
    api = _FakeApi();
    original = ApiClient.instance.dio.httpClientAdapter;
    ApiClient.instance.dio.httpClientAdapter = api;
  });
  tearDown(() => ApiClient.instance.dio.httpClientAdapter = original);

  Widget picker({required ValueChanged<PhAddress> onChanged, GlobalKey<FormState>? formKey, bool door = true}) => ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: PhAddressPicker(initial: PhAddress.empty, door: door, onChanged: onChanged),
              ),
            ),
          ),
        ),
      );

  testWidgets('an NCR city is picked straight from the region, then its barangay', (tester) async {
    PhAddress? picked;
    await tester.pumpWidget(picker(onChanged: (a) => picked = a));

    await _choose(tester, 'Region', 'National Capital Region (NCR)');
    await _choose(tester, 'Province or city', 'Quezon City');
    // No province, so no city list: straight to the barangay.
    expect(find.text('City or municipality'), findsNothing);
    await _choose(tester, 'Barangay', 'Bagong Pag-asa');

    expect(picked!.province, isNull);
    expect(picked!.formatted, 'Bagong Pag-asa, Quezon City, Metro Manila');
    expect(picked!.toDoorJson(), {'barangay_code': '137404009'});
  });

  testWidgets('a province leads to its cities; a new region clears what was below', (tester) async {
    PhAddress? picked;
    await tester.pumpWidget(picker(onChanged: (a) => picked = a));

    await _choose(tester, 'Region', 'Region IV-A (CALABARZON)');
    await _choose(tester, 'Province or city', 'Laguna');
    await _choose(tester, 'City or municipality', 'City of Santa Rosa');
    await _choose(tester, 'Barangay', 'Balibago');
    expect(picked!.formatted, 'Balibago, City of Santa Rosa, Laguna');

    await _choose(tester, 'Region', 'National Capital Region (NCR)');
    expect(picked!.province, isNull);
    expect(picked!.city, isNull);
    expect(picked!.barangay, isNull);
  });

  testWidgets('a door address needs a barangay; a service area only a city', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(picker(onChanged: (_) {}, formKey: formKey));

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Choose your barangay.'), findsOneWidget);

    final areaKey = GlobalKey<FormState>();
    await tester.pumpWidget(picker(onChanged: (_) {}, formKey: areaKey, door: false));
    await _choose(tester, 'Region', 'National Capital Region (NCR)');
    await _choose(tester, 'Province or city', 'Quezon City');
    expect(areaKey.currentState!.validate(), isTrue);
  });

  test('the profile sends the structured address, not free text', () async {
    final current = UserModel(id: '1', role: UserRole.client, firstName: 'Juan', lastName: 'Dela Cruz', email: 'juan@example.com', createdAt: DateTime(2026));
    await ProfileService().updateProfile(current, addressDetails: {'barangay_code': '137404009', 'street': '123 Rizal St'});

    final body = api.requests.single.data as Map;
    expect(body['address_details'], {'barangay_code': '137404009', 'street': '123 Rizal St'});
    expect(body.containsKey('address'), isFalse);
  });

  test('a booking sends where the provider should go as codes', () async {
    try {
      await BookingService().createBooking(
        serviceId: '7',
        scheduledDate: DateTime(2026, 11, 2, 10),
        serviceAddressDetails: {'barangay_code': '137404009'},
      );
    } catch (_) {
      // The fake reply is not a full booking; only the request matters here.
    }

    final body = api.requests.single.data as Map;
    expect(body['service_address_details'], {'barangay_code': '137404009'});
    expect(body.containsKey('service_address'), isFalse);
  });

  test('saved addresses are read back for the pickers, and cached with the session', () {
    final details = {
      'region': {'code': '130000000', 'name': 'National Capital Region (NCR)'},
      'province': null,
      'city': {'code': '137404000', 'name': 'Quezon City'},
      'barangay': {'code': '137404009', 'name': 'Bagong Pag-asa'},
      'street': '123 Rizal St',
      'postal_code': '1105',
    };
    final user = UserModel.fromJson({'id': 1, 'first_name': 'Juan', 'last_name': 'Dela Cruz', 'email': 'juan@example.com', 'role_id': 4, 'address_details': details});

    expect(user.addressDetails?.barangay?.code, '137404009');
    // The cached session keeps it, so Edit Profile opens pre-filled offline.
    expect(UserModel.fromJson(user.toJson()).addressDetails?.formatted, '123 Rizal St, Bagong Pag-asa, Quezon City, Metro Manila 1105');

    final service = ProviderServiceModel.fromJson({
      'id': 3, 'title': 'Aircon Cleaning', 'price': '500.00', 'category_id': 2,
      'location': 'Cainta, Rizal',
      'location_details': {'region': {'code': '040000000', 'name': 'Region IV-A (CALABARZON)'}, 'province': {'code': '045800000', 'name': 'Rizal'}, 'city': {'code': '045805000', 'name': 'Cainta'}, 'barangay': null},
    });
    expect(service.locationDetails?.toAreaJson(), {'city_code': '045805000'});
  });
}
