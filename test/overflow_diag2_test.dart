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
import 'package:skilllink_mobile/views/client/client_shell.dart';
import 'package:skilllink_mobile/views/client/favorites_screen.dart';
import 'package:skilllink_mobile/views/client/service_details_screen.dart';
import 'package:skilllink_mobile/views/guest/search_screen.dart';
import 'package:skilllink_mobile/views/guest/terms_screen.dart';
import 'package:skilllink_mobile/views/provider/calendar_screen.dart';
import 'package:skilllink_mobile/views/provider/dashboard_screen.dart';
import 'package:skilllink_mobile/views/provider/earnings_screen.dart';
import 'package:skilllink_mobile/views/provider/statistics_screen.dart';
import 'package:skilllink_mobile/views/provider/booking_requests_screen.dart';
import 'package:skilllink_mobile/views/provider/withdrawal_history_screen.dart';

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
    await _pump(tester, const SearchScreen(), const Size(320, 568));
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
    await _pump(tester, const SearchScreen(), const Size(320, 568));
  });
  testWidgets('service details 390', (tester) async {
    await _pump(tester, const ServiceDetailsScreen(serviceId: 'SV-1'), const Size(390, 844));
  });
}
