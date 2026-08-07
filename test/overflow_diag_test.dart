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
import 'package:skilllink_mobile/views/guest/onboarding_screen.dart';
import 'package:skilllink_mobile/views/guest/register_screen.dart';
import 'package:skilllink_mobile/views/guest/welcome_screen.dart';
import 'package:skilllink_mobile/views/provider/provider_onboarding_screen.dart';

Widget _app(Widget home, double textScale) {
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

Future<void> _pump(WidgetTester tester, Widget screen, Size size, double ts) async {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final msg = details.exception.toString();
    if (msg.contains('overflowed')) {
      final buf = StringBuffer('=== OVERFLOW @ $size ts$ts ===\n$msg\n');
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
  await tester.pumpWidget(_app(screen, ts));
  await tester.pump(const Duration(milliseconds: 100));
  tester.takeException();
}

void main() {
  testWidgets('onboarding 320x568 ts1.0', (tester) async {
    await _pump(tester, const OnboardingScreen(), const Size(320, 568), 1.0);
  });
  testWidgets('onboarding 390x844 ts2.0', (tester) async {
    await _pump(tester, const OnboardingScreen(), const Size(390, 844), 2.0);
  });
  testWidgets('welcome 320x568 ts1.0', (tester) async {
    await _pump(tester, const WelcomeScreen(), const Size(320, 568), 1.0);
  });
  testWidgets('welcome 390x844 ts2.0', (tester) async {
    await _pump(tester, const WelcomeScreen(), const Size(390, 844), 2.0);
  });
  testWidgets('register 320x568 ts1.5', (tester) async {
    await _pump(tester, const RegisterScreen(), const Size(320, 568), 1.5);
  });
  testWidgets('forgot 390x844 ts2.0', (tester) async {
    await _pump(tester, const ForgotPasswordScreen(), const Size(390, 844), 2.0);
  });
  testWidgets('provider onboarding 320x568 ts2.0', (tester) async {
    await _pump(tester, const ProviderOnboardingScreen(), const Size(320, 568), 2.0);
  });
  testWidgets('provider onboarding 390x844 ts1.5', (tester) async {
    await _pump(tester, const ProviderOnboardingScreen(), const Size(390, 844), 1.5);
  });
  testWidgets('provider onboarding sweep order', (tester) async {
    await _pump(tester, const ProviderOnboardingScreen(), const Size(390, 844), 1.0);
    await _pump(tester, const ProviderOnboardingScreen(), const Size(390, 844), 1.5);
    await _pump(tester, const ProviderOnboardingScreen(), const Size(390, 844), 2.0);
  });
}
