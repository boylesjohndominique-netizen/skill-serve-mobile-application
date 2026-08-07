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
import 'package:skilllink_mobile/controllers/theme_controller.dart';
import 'package:skilllink_mobile/core/theme/app_theme.dart';
import 'package:skilllink_mobile/views/guest/forgot_password_screen.dart';
import 'package:skilllink_mobile/views/guest/login_screen.dart';
import 'package:skilllink_mobile/views/guest/onboarding_screen.dart';
import 'package:skilllink_mobile/views/guest/register_screen.dart';
import 'package:skilllink_mobile/views/guest/welcome_screen.dart';
import 'package:skilllink_mobile/views/provider/provider_onboarding_screen.dart';

Widget _app(Widget home, {double textScale = 1.0}) {
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
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: home,
      ),
    ),
  );
}

const _sizes = [
  Size(390, 844),
  Size(360, 690),
  Size(320, 568),
  Size(390, 500), // short viewport (landscape-ish / keyboard open)
  Size(390, 360), // very short viewport
];

Future<void> _pumpScreen(WidgetTester tester, Widget screen) async {
  final failures = <String>[];
  for (final size in _sizes) {
    for (final ts in [1.0, 1.5, 2.0]) {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(screen, textScale: ts));
      await tester.pump(const Duration(milliseconds: 100));
      final ex = tester.takeException();
      if (ex != null) {
        final details = ex is FlutterError ? ex.toStringDeep() : '$ex';
        failures.add('size ${size.width}x${size.height} textScale $ts:\n$details');
      }
    }
  }
  expect(failures, isEmpty,
      reason: 'Overflow/exception on $screen:\n${failures.join('\n\n\n')}');
}

void main() {
  for (final entry in <String, Widget>{
    'login': const LoginScreen(),
    'register': const RegisterScreen(),
    'onboarding': const OnboardingScreen(),
    'welcome': const WelcomeScreen(),
    'forgot password': const ForgotPasswordScreen(),
    'provider onboarding': const ProviderOnboardingScreen(),
  }.entries) {
    testWidgets('$entry.key screen has no overflow', (tester) async {
      await _pumpScreen(tester, entry.value);
    });
  }
}
