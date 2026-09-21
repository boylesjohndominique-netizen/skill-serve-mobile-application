import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'features/auth/controllers/auth_controller.dart';
import 'features/notifications/views/notification_poller.dart';
import 'features/booking/controllers/booking_controller.dart';
import 'features/booking/controllers/provider_booking_controller.dart';
import 'features/marketplace/controllers/favorites_controller.dart';
import 'features/marketplace/controllers/discovery_controller.dart';
import 'features/marketplace/controllers/marketplace_controller.dart';
import 'features/notifications/controllers/notification_controller.dart';
import 'features/messaging/controllers/chat_controller.dart';
import 'features/payments/controllers/payment_controller.dart';
import 'features/provider/controllers/portfolio_controller.dart';
import 'features/provider/controllers/provider_services_controller.dart';
import 'features/reports/controllers/report_controller.dart';
import 'features/reviews/controllers/review_controller.dart';
import 'features/support/controllers/support_controller.dart';
import 'features/settings/controllers/preferences_controller.dart';
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
        // Settings belong to the account, so the controller follows the
        // session: signing in pulls the user's own settings, signing out
        // drops them.
        ChangeNotifierProxyProvider<AuthController, PreferencesController>(
          create: (_) => PreferencesController()..initialize(),
          update: (_, auth, preferences) => preferences!
            ..onAuthChanged(signedIn: auth.status == AuthStatus.authenticated),
        ),
        ChangeNotifierProvider(create: (_) => MarketplaceController()),
        // Recent searches are device-local, so Explore follows the session
        // and forgets them when the user signs out.
        ChangeNotifierProxyProvider<AuthController, DiscoveryController>(
          create: (_) => DiscoveryController(),
          update: (_, auth, discovery) => discovery!
            ..onAuthChanged(signedIn: auth.status == AuthStatus.authenticated),
        ),
        // Favorites live on the server and belong to a customer account.
        ChangeNotifierProxyProvider<AuthController, FavoritesController>(
          create: (_) => FavoritesController(),
          update: (_, auth, favorites) => favorites!
            ..onAuthChanged(
              signedInAsClient: auth.status == AuthStatus.authenticated && auth.isClient,
            ),
        ),
        ChangeNotifierProvider(create: (_) => BookingController()),
        ChangeNotifierProvider(create: (_) => ProviderBookingController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => PortfolioController()),
        ChangeNotifierProvider(create: (_) => ProviderServicesController()),
        ChangeNotifierProvider(create: (_) => PaymentController()),
        ChangeNotifierProvider(create: (_) => ReportController()),
        ChangeNotifierProvider(create: (_) => ReviewController()),
        ChangeNotifierProvider(create: (_) => SupportController()),
      ],
      child: Consumer<PreferencesController>(
        builder: (context, preferences, _) {
          // "Reduce motion" is honoured globally rather than per screen:
          // shrinking the scheduler's time scale lets every animation —
          // including the flutter_animate entrances used across the app —
          // settle on its final frame almost immediately, so content still
          // appears, just without the movement.
          timeDilation = preferences.reduceMotion ? 0.01 : 1.0;

          return ScreenUtilInit(
            // Base design size — most modern mid-range phones (e.g. Pixel/Galaxy) at 1x density.
            designSize: const Size(390, 844),
            minTextAdapt: true,
            builder: (context, child) => MaterialApp.router(
              title: AppConfig.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: preferences.themeMode,
              routerConfig: _runtimeRouter,
              builder: (context, widget) {
                _startConnectivityMonitoring(context);
                return ResponsiveBreakpoints.builder(
                  // Framework-driven motion (page transitions, implicit
                  // animations) reads this flag directly.
                  child: MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(disableAnimations: preferences.reduceMotion),
                    child: NotificationPoller(
                        child: widget ?? const SizedBox.shrink()),
                  ),
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
