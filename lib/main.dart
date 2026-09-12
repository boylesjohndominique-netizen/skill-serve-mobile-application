import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'features/auth/controllers/auth_controller.dart';
import 'features/booking/controllers/booking_controller.dart';
import 'features/booking/controllers/provider_booking_controller.dart';
import 'features/marketplace/controllers/favorites_controller.dart';
import 'features/marketplace/controllers/marketplace_controller.dart';
import 'features/notifications/controllers/notification_controller.dart';
import 'features/messaging/controllers/chat_controller.dart';
import 'features/payments/controllers/payment_controller.dart';
import 'features/provider/controllers/portfolio_controller.dart';
import 'features/reports/controllers/report_controller.dart';
import 'features/settings/controllers/preferences_controller.dart';
import 'features/settings/controllers/theme_controller.dart';
import 'core/config/app_config.dart';
import 'core/services/api_client.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/feedback/connectivity_gate.dart';
import 'routes/app_router.dart';

final _runtimeAuthController = AuthController()..initialize();
final _runtimeRouter = createAuthenticatedRouter(_runtimeAuthController);

void main() {
  // Wake the sleeping free-tier Render backend as early as possible so the
  // user's first request doesn't bear the ~60-75 s cold start.
  ApiClient.instance.warmUp();
  runApp(const SkillLinkApp());
}

/// Starts global connectivity monitoring once the first frame renders and a
/// Navigator exists to host the no-internet modal.
void _startConnectivityMonitoring(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ConnectivityGate.initialize(context);
  });
}

class SkillLinkApp extends StatelessWidget {
  const SkillLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _runtimeAuthController),
        ChangeNotifierProvider(create: (_) => ThemeController()..initialize()),
        ChangeNotifierProvider(
            create: (_) => PreferencesController()..initialize()),
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
              routerConfig: _runtimeRouter,
              builder: (context, widget) {
                _startConnectivityMonitoring(context);
                return ResponsiveBreakpoints.builder(
                  child: widget ?? const SizedBox.shrink(),
                  breakpoints: const [
                    Breakpoint(start: 0, end: 450, name: MOBILE),
                    Breakpoint(start: 451, end: 800, name: TABLET),
                    Breakpoint(start: 801, end: 1920, name: DESKTOP),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
