import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:skilllink_mobile/controllers/auth_controller.dart';
import 'package:skilllink_mobile/controllers/booking_controller.dart';
import 'package:skilllink_mobile/controllers/chat_controller.dart';
import 'package:skilllink_mobile/controllers/favorites_controller.dart';
import 'package:skilllink_mobile/controllers/marketplace_controller.dart';
import 'package:skilllink_mobile/controllers/notification_controller.dart';
import 'package:skilllink_mobile/controllers/payment_controller.dart';
import 'package:skilllink_mobile/controllers/portfolio_controller.dart';
import 'package:skilllink_mobile/controllers/provider_booking_controller.dart';
import 'package:skilllink_mobile/controllers/report_controller.dart';
import 'package:go_router/go_router.dart';

import 'package:skilllink_mobile/controllers/theme_controller.dart';
import 'package:skilllink_mobile/core/theme/app_theme.dart';
import 'package:skilllink_mobile/routes/app_router.dart';

final _routes = <String>[
  // Guest
  '/browse',
  '/categories',
  '/search',
  '/about',
  '/contact',
  '/terms',
  '/privacy',
  '/provider-preview/PV-100',
  // Client
  '/client',
  '/service-details/SV-1',
  '/provider-profile/PV-100',
  '/booking-history',
  '/favorites',
  '/chat-conversation/CV-0',
  '/payments',
  '/my-reports',
  '/notifications',
  '/reviews/PV-100',
  '/booking-details/BK-5000',
  '/help-center',
  '/file-report',
  // Provider
  '/provider',
  '/statistics',
  '/my-services',
  '/portfolio',
  '/calendar',
  '/booking-requests',
  '/active-jobs',
  '/completed-jobs',
  '/earnings',
  '/withdrawal-history',
  '/verification-status',
  '/provider-badges',
];

Widget _app(String route) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthController()),
      ChangeNotifierProvider(create: (_) => ThemeController()),
      ChangeNotifierProvider(create: (_) => MarketplaceController()),
      ChangeNotifierProvider(create: (_) => FavoritesController()),
      ChangeNotifierProvider(create: (_) => BookingController()),
      ChangeNotifierProvider(create: (_) => ProviderBookingController()),
      ChangeNotifierProvider(create: (_) => NotificationController()),
      ChangeNotifierProvider(create: (_) => ChatController()),
      ChangeNotifierProvider(create: (_) => PortfolioController()),
      ChangeNotifierProvider(create: (_) => PaymentController()),
      ChangeNotifierProvider(create: (_) => ReportController()),
    ],
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      // A fresh router per test starts directly on the route under test, so
      // no navigation-transition frames pollute the layout check.
      builder: (context, child) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: GoRouter(initialLocation: route, routes: appRoutes),
      ),
    ),
  );
}

void main() {
  for (final route in _routes) {
    testWidgets('no overflow on $route', (tester) async {
      for (final size in [const Size(390, 844), const Size(320, 568)]) {
        final original = FlutterError.onError;
        FlutterError.onError = (details) {
          final msg = details.exception.toString();
          if (msg.contains('overflowed')) {
            final buf = StringBuffer('=== OVERFLOW @ $route $size ===\n$msg\n');
            details.informationCollector?.call().forEach((n) => buf.writeln(n.toString()));
            // ignore: avoid_print
            print(buf.toString());
          }
          original?.call(details);
        };
        addTearDown(() => FlutterError.onError = original);
        tester.view.physicalSize = size * 3;
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_app(route));
        await tester.pump(const Duration(milliseconds: 50));
        // Let mock data (simulated network delay ~500ms) arrive.
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 200));
        final ex = tester.takeException();
        if (ex != null) {
          final msg = ex.toString();
          if (msg.contains('overflowed')) {
            fail('OVERFLOW on $route at ${size.width}x${size.height}: $msg');
          }
          // Non-layout exceptions (e.g. mock/state noise) are noted but
          // don't fail the sweep — we only care about layout bugs here.
          // ignore: avoid_print
          print('NOTE (non-overflow) $route @ $size: $msg');
        }
      }
    });
  }
}
