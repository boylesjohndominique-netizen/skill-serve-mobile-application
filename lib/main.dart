import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'controllers/auth_controller.dart';
import 'controllers/booking_controller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/marketplace_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/payment_controller.dart';
import 'controllers/portfolio_controller.dart';
import 'controllers/report_controller.dart';
import 'controllers/provider_booking_controller.dart';
import 'controllers/theme_controller.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

void main() {
  runApp(const SkillLinkApp());
}

class SkillLinkApp extends StatelessWidget {
  const SkillLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return ScreenUtilInit(
            // Base design size — most modern mid-range phones (e.g. Pixel/Galaxy) at 1x density.
            designSize: const Size(390, 844),
            minTextAdapt: true,
            builder: (context, child) => MaterialApp.router(
              title: AppConfig.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeController.mode,
              routerConfig: appRouter,
              builder: (context, widget) => ResponsiveBreakpoints.builder(
                child: widget ?? const SizedBox.shrink(),
                breakpoints: const [
                  Breakpoint(start: 0, end: 450, name: MOBILE),
                  Breakpoint(start: 451, end: 800, name: TABLET),
                  Breakpoint(start: 801, end: 1920, name: DESKTOP),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
