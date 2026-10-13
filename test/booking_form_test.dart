import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skillserve_mobile/core/theme/app_theme.dart';
import 'package:skillserve_mobile/features/auth/controllers/auth_controller.dart';
import 'package:skillserve_mobile/features/booking/views/booking_form_screen.dart';
import 'package:skillserve_mobile/features/marketplace/models/provider_model.dart';
import 'package:skillserve_mobile/features/marketplace/services/service_service.dart';

/// A provider with two bookable services, as `GET /providers/{provider}`
/// returns it.
class _FakeCatalog extends ServiceService {
  @override
  Future<ProviderModel> getProviderById(String id) async => ProviderModel.fromJson({
        'id': 7,
        'business_name': 'Fix-It Shop',
        'verification_status': 'verified',
        'services': [
          {'id': 1, 'title': 'Aircon cleaning', 'price': '800.00', 'price_type': 'fixed', 'duration': '2 hours'},
          {'id': 3, 'title': 'Laptop repair', 'price': '1500.00', 'price_type': 'fixed', 'duration': '3 hours'},
        ],
      });
}

Future<void> _pumpForm(WidgetTester tester, {String? serviceId}) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AuthController(),
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MaterialApp(
          theme: AppTheme.light,
          home: BookingFormScreen(providerId: '7', serviceId: serviceId, catalog: _FakeCatalog()),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

/// Unmounts so the entrance animations leave no timers behind.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('booking a service already picked skips choosing a service', (tester) async {
    await _pumpForm(tester, serviceId: '3');

    expect(find.text('Choose a service'), findsNothing);
    expect(find.text('When do you need it?'), findsOneWidget);
    // The chosen service is named above the schedule.
    expect(find.text('Laptop repair'), findsOneWidget);
    // Three steps, and no Back button on the first of them.
    expect(find.text('Service'), findsNothing);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Back'), findsNothing);
    await _unmount(tester);
  });

  testWidgets('booking a provider starts by choosing the service', (tester) async {
    await _pumpForm(tester);

    expect(find.text('Choose a service'), findsOneWidget);
    expect(find.text('Service'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('a service that is no longer bookable falls back to choosing one', (tester) async {
    await _pumpForm(tester, serviceId: '99');

    expect(find.text('Choose a service'), findsOneWidget);
    await _unmount(tester);
  });
}
