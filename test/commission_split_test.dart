import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skilllink_mobile/core/services/api_client.dart';
import 'package:skilllink_mobile/core/theme/app_theme.dart';
import 'package:skilllink_mobile/features/provider/models/commission_model.dart';
import 'package:skilllink_mobile/features/provider/models/provider_service_model.dart';
import 'package:skilllink_mobile/features/provider/views/service_form.dart';

/// Answers the two calls the service form makes: the categories, and the
/// commission preview at a flat 15% of the requested amount.
class _FakeApi implements HttpClientAdapter {
  final previewAmounts = <String>[];

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final Object data;
    if (options.path.endsWith('/categories')) {
      data = [
        {'id': 3, 'name': 'Appliance Repair', 'subcategories': []},
      ];
    } else if (options.path.endsWith('/commission-preview')) {
      final amount = double.parse('${options.queryParameters['amount']}');
      previewAmounts.add(amount.toStringAsFixed(2));
      data = {
        'amount': amount.toStringAsFixed(2),
        'commission_rate': '15.00',
        'commission_amount': (amount * 0.15).toStringAsFixed(2),
        'net_amount': (amount * 0.85).toStringAsFixed(2),
        'currency': 'PHP',
        'source': 'tier',
      };
    } else {
      return ResponseBody.fromString('{}', 404, headers: {Headers.contentTypeHeader: ['application/json']});
    }
    return ResponseBody.fromString(jsonEncode({'success': true, 'data': data}), 200, headers: {
      Headers.contentTypeHeader: ['application/json'],
    });
  }

  @override
  void close({bool force = false}) {}
}

Widget _form({ProviderServiceModel? existing}) => ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ServiceForm(existing: existing, onSubmit: (_) async {}, submitting: false),
          ),
        ),
      ),
    );

void main() {
  group('CommissionSplit', () {
    test('reads the preview response', () {
      final split = CommissionSplit.fromJson({
        'amount': '500.00',
        'commission_rate': '15.00',
        'commission_amount': '75.00',
        'net_amount': '425.00',
      });

      expect(split.amount, '500.00');
      expect(split.commissionAmount, '75.00');
      expect(split.netAmount, '425.00');
      expect(split.rateLabel, '15%');
    });

    test('reads a service earnings block, which names the base price', () {
      final split = CommissionSplit.fromJson({
        'price': '200.00',
        'commission_rate': '12.50',
        'commission_amount': '25.00',
        'net_amount': '175.00',
      });

      expect(split.amount, '200.00');
      expect(split.rateLabel, '12.5%');
    });

    test('a provider service carries its earnings when the API sends them', () {
      ProviderServiceModel parse(Map<String, dynamic> extra) => ProviderServiceModel.fromJson({
            'id': 1,
            'title': 'Aircon Cleaning',
            'price': '500.00',
            'category_id': 3,
            ...extra,
          });

      final service = parse({
        'earnings': {'price': '500.00', 'commission_rate': '15.00', 'commission_amount': '75.00', 'net_amount': '425.00'},
      });
      expect(service.earnings?.netAmount, '425.00');
      expect(parse({}).earnings, isNull);
    });
  });

  group('service form', () {
    late _FakeApi api;
    late HttpClientAdapter original;

    setUp(() {
      // The API client reads the saved token, which first checks
      // SharedPreferences for tokens left by older builds.
      SharedPreferences.setMockInitialValues({});
      api = _FakeApi();
      original = ApiClient.instance.dio.httpClientAdapter;
      ApiClient.instance.dio.httpClientAdapter = api;
    });
    tearDown(() => ApiClient.instance.dio.httpClientAdapter = original);

    Future<void> settle(WidgetTester tester) async {
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
    }

    testWidgets('shows what the provider keeps once a price is typed', (tester) async {
      await tester.pumpWidget(_form());
      await tester.pumpAndSettle();

      expect(find.textContaining('you keep'), findsNothing);

      await tester.enterText(find.widgetWithText(TextFormField, '1500'), '50');
      await tester.enterText(find.widgetWithText(TextFormField, '1500'), '500');
      await settle(tester);

      expect(find.text('SkillServe 15% · ₱75.00 · you keep ₱425.00'), findsOneWidget);
      // Typing pauses are debounced: only the final price was asked about.
      expect(api.previewAmounts, ['500.00']);

      await tester.enterText(find.widgetWithText(TextFormField, '1500'), '');
      await settle(tester);
      expect(find.textContaining('you keep'), findsNothing);
    });

    testWidgets('an existing service shows its split straight away', (tester) async {
      final existing = ProviderServiceModel.fromJson({
        'id': 1,
        'title': 'Aircon Cleaning',
        'price': '200.00',
        'price_type': 'hourly',
        'category_id': 3,
      });

      await tester.pumpWidget(_form(existing: existing));
      await settle(tester);

      expect(find.text('SkillServe 15% · ₱30.00 · you keep ₱170.00 per hour'), findsOneWidget);
    });
  });
}
