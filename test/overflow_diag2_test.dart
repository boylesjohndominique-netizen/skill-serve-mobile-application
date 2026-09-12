import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:skilllink_mobile/features/auth/controllers/auth_controller.dart';
import 'package:skilllink_mobile/features/booking/controllers/booking_controller.dart';
import 'package:skilllink_mobile/features/messaging/controllers/chat_controller.dart';
import 'package:skilllink_mobile/features/marketplace/controllers/favorites_controller.dart';
import 'package:skilllink_mobile/features/marketplace/controllers/marketplace_controller.dart';
import 'package:skilllink_mobile/features/notifications/controllers/notification_controller.dart';
import 'package:skilllink_mobile/features/payments/controllers/payment_controller.dart';
import 'package:skilllink_mobile/features/provider/controllers/portfolio_controller.dart';
import 'package:skilllink_mobile/features/booking/controllers/provider_booking_controller.dart';
import 'package:skilllink_mobile/features/reports/controllers/report_controller.dart';
import 'package:skilllink_mobile/features/settings/controllers/theme_controller.dart';
import 'package:skilllink_mobile/core/theme/app_theme.dart';
import 'package:skilllink_mobile/features/marketplace/views/client_shell.dart';
import 'package:skilllink_mobile/features/marketplace/views/favorites_screen.dart';
import 'package:skilllink_mobile/features/marketplace/views/service_details_screen.dart';
import 'package:skilllink_mobile/features/marketplace/views/search_screen.dart';
import 'package:skilllink_mobile/features/settings/views/terms_screen.dart';
import 'package:skilllink_mobile/features/provider/views/calendar_screen.dart';
import 'package:skilllink_mobile/features/provider/views/dashboard_screen.dart';
import 'package:skilllink_mobile/features/provider/views/earnings_screen.dart';
import 'package:skilllink_mobile/features/provider/views/statistics_screen.dart';
import 'package:skilllink_mobile/features/provider/views/booking_requests_screen.dart';
import 'package:skilllink_mobile/features/provider/views/withdrawal_history_screen.dart';

Widget _app(Widget home) {
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
        home: home,
      ),
    ),
  );
}

Future<void> _pump(WidgetTester tester, Widget screen, Size size) async {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    final msg = details.exception.toString();
    if (msg.contains('overflowed')) {
      final buf = StringBuffer('=== OVERFLOW @ ${screen.runtimeType} $size ===\n$msg\n');
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
  await tester.pumpWidget(_app(screen));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(milliseconds: 200));
  tester.takeException();
}

void main() {
  testWidgets('favorites 320', (tester) async {
    await _pump(tester, const FavoritesScreen(), const Size(320, 568));
  });
  testWidgets('provider dashboard 390', (tester) async {
    await _pump(tester, const ProviderDashboardScreen(), const Size(390, 844));
  });
  testWidgets('withdrawal history 390', (tester) async {
    await _pump(tester, const WithdrawalHistoryScreen(), const Size(390, 844));
  });
  testWidgets('client shell 390', (tester) async {
    await _pump(tester, const ClientShell(), const Size(390, 844));
  });
  testWidgets('search 320', (tester) async {
    await _pump(tester, const ClientSearchScreen(), const Size(320, 568));
  });
  testWidgets('terms 320', (tester) async {
    await _pump(tester, const TermsScreen(), const Size(320, 568));
  });
  testWidgets('booking requests 320', (tester) async {
    await _pump(tester, const BookingRequestsScreen(), const Size(320, 568));
  });
  testWidgets('calendar 320', (tester) async {
    await _pump(tester, const CalendarScreen(), const Size(320, 568));
  });
  testWidgets('withdrawal 390', (tester) async {
    await _pump(tester, const WithdrawalHistoryScreen(), const Size(390, 844));
  });
  testWidgets('statistics 390', (tester) async {
    await _pump(tester, const StatisticsScreen(), const Size(390, 844));
  });
  testWidgets('earnings 320', (tester) async {
    await _pump(tester, const EarningsScreen(), const Size(320, 568));
  });
  testWidgets('terms 320', (tester) async {
    await _pump(tester, const TermsScreen(), const Size(320, 568));
  });
  testWidgets('search 320', (tester) async {
    await _pump(tester, const ClientSearchScreen(), const Size(320, 568));
  });
  testWidgets('service details 390', (tester) async {
    await _pump(tester, const ServiceDetailsScreen(serviceId: 'SV-1'), const Size(390, 844));
  });
}
