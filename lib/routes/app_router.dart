import 'package:go_router/go_router.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/booking/models/booking_model.dart';

// Auth
import '../features/auth/views/splash_screen.dart';
import '../features/auth/views/onboarding_screen.dart';
import '../features/auth/views/welcome_screen.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/auth/views/forgot_password_screen.dart';

// Marketplace
import '../features/marketplace/views/browse_services_screen.dart';
import '../features/marketplace/views/categories_screen.dart';
import '../features/marketplace/views/search_screen.dart';
import '../features/marketplace/views/client_shell.dart';
import '../features/marketplace/views/provider_preview_screen.dart';
import '../features/marketplace/views/provider_profile_screen.dart';
import '../features/marketplace/views/service_details_screen.dart';
import '../features/marketplace/views/portfolio_gallery_screen.dart';
import '../features/marketplace/views/favorites_screen.dart';

// Booking
import '../features/booking/views/booking_form_screen.dart';
import '../features/booking/views/booking_confirmation_screen.dart';
import '../features/booking/views/booking_history_screen.dart';
import '../features/booking/views/booking_details_screen.dart';

// Profile
import '../features/profile/views/edit_profile_screen.dart';
import '../features/profile/views/change_password_screen.dart';
import '../features/profile/views/account_data_screen.dart';
import '../features/profile/views/account_deactivation_screen.dart';
import '../features/profile/views/account_deletion_screen.dart';

// Messaging
import '../features/messaging/views/chat_conversation_screen.dart';

// Payments
import '../features/payments/views/payments_screen.dart';
import '../features/payments/views/payment_details_screen.dart';

// Reports
import '../features/reports/views/file_report_screen.dart';
import '../features/reports/views/my_reports_screen.dart';

// Reviews
import '../features/reviews/views/write_review_screen.dart';
import '../features/reviews/views/reviews_screen.dart';

// Provider
import '../features/provider/views/provider_shell.dart';
import '../features/provider/views/statistics_screen.dart';
import '../features/provider/views/my_services_screen.dart';
import '../features/provider/views/add_service_screen.dart';
import '../features/provider/views/edit_service_screen.dart';
import '../features/provider/views/upload_portfolio_screen.dart';
import '../features/provider/views/portfolio_screen.dart';
import '../features/provider/views/provider_onboarding_screen.dart';
import '../features/provider/views/badges_screen.dart';

// Booking (provider views)
import '../features/provider/views/calendar_screen.dart';
import '../features/provider/views/booking_requests_screen.dart';
import '../features/provider/views/active_jobs_screen.dart';
import '../features/provider/views/completed_jobs_screen.dart';

// Provider earnings
import '../features/provider/views/earnings_screen.dart';
import '../features/provider/views/withdrawal_history_screen.dart';
import '../features/provider/views/verification_status_screen.dart';

// Settings
import '../features/settings/views/about_screen.dart';
import '../features/settings/views/contact_screen.dart';
import '../features/settings/views/terms_screen.dart';
import '../features/settings/views/privacy_screen.dart';
import '../features/settings/views/help_center_screen.dart';
import '../features/settings/views/activity_history_screen.dart';
import '../features/notifications/views/preferences_screens.dart';

// Notifications
import '../features/notifications/views/notifications_screen.dart';
import '../features/notifications/views/security_notifications_screen.dart';

// Client shell

/// Central route table. Grouped by persona to mirror lib/views/ — Guest,
/// Client, and Provider each own their sub-tree, with a few screens
/// (Notifications, Reviews, Booking Details, static info pages) shared
/// across personas via top-level routes.
/// Top-level route table — also importable by tests that build a fresh
/// [GoRouter] per scenario (avoids shared-router state bleed).
final List<RouteBase> appRoutes = [
  GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
  GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
  GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen()),
  GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
  GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
  GoRoute(
      path: '/register', builder: (context, state) => const RegisterScreen()),
  GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen()),
  GoRoute(
      path: '/browse',
      builder: (context, state) => const BrowseServicesScreen()),
  GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoriesScreen()),
  GoRoute(path: '/search', builder: (context, state) => const ClientSearchScreen()),
  GoRoute(
    path: '/provider-preview/:id',
    builder: (context, state) =>
        ProviderPreviewScreen(providerId: state.pathParameters['id']!),
  ),
  GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
  GoRoute(path: '/contact', builder: (context, state) => const ContactScreen()),
  GoRoute(path: '/terms', builder: (context, state) => const TermsScreen()),
  GoRoute(path: '/privacy', builder: (context, state) => const PrivacyScreen()),

  // Client shell (bottom-nav: Home / Search / Bookings / Chat / Profile)
  GoRoute(path: '/client', builder: (context, state) => const ClientShell()),
  GoRoute(
    path: '/provider-profile/:id',
    builder: (context, state) =>
        ProviderProfileScreen(providerId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/service-details/:id',
    builder: (context, state) =>
        ServiceDetailsScreen(serviceId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/portfolio-gallery/:id',
    builder: (context, state) =>
        PortfolioGalleryScreen(providerId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/booking-form/:providerId',
    builder: (context, state) =>
        BookingFormScreen(providerId: state.pathParameters['providerId']!),
  ),
  GoRoute(
    path: '/booking-confirmation',
    builder: (context, state) =>
        BookingConfirmationScreen(booking: state.extra as BookingModel),
  ),
  GoRoute(
      path: '/booking-history',
      builder: (context, state) => const BookingHistoryScreen()),
  GoRoute(
    path: '/booking-details/:id',
    builder: (context, state) =>
        BookingDetailsScreen(bookingId: state.pathParameters['id']!),
  ),
  GoRoute(
      path: '/favorites', builder: (context, state) => const FavoritesScreen()),
  GoRoute(
    path: '/chat-conversation/:id',
    builder: (context, state) =>
        ChatConversationScreen(conversationId: state.pathParameters['id']!),
  ),
  GoRoute(
      path: '/payments', builder: (context, state) => const PaymentsScreen()),
  GoRoute(
    path: '/payment-details/:id',
    builder: (context, state) =>
        PaymentDetailsScreen(paymentId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/file-report',
    builder: (context, state) =>
        FileReportScreen(bookingId: state.uri.queryParameters['bookingId']),
  ),
  GoRoute(
      path: '/my-reports',
      builder: (context, state) => const MyReportsScreen()),
  GoRoute(
    path: '/write-review/:bookingId',
    builder: (context, state) =>
        WriteReviewScreen(bookingId: state.pathParameters['bookingId']!),
  ),
  GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen()),
  GoRoute(
      path: '/change-password',
      builder: (context, state) => const ChangePasswordScreen()),
  GoRoute(
      path: '/help-center',
      builder: (context, state) => const HelpCenterScreen()),
  GoRoute(
      path: '/activity-history',
      builder: (context, state) => const ActivityHistoryScreen()),
  GoRoute(
      path: '/notification-preferences',
      builder: (context, state) => const NotificationPreferencesScreen()),
  GoRoute(
      path: '/privacy-settings',
      builder: (context, state) => const PrivacySettingsScreen()),
  GoRoute(
      path: '/application-preferences',
      builder: (context, state) => const ApplicationPreferencesScreen()),
  GoRoute(
      path: '/security-activity',
      builder: (context, state) => const SecurityNotificationsScreen()),
  GoRoute(
      path: '/account-data',
      builder: (context, state) => const AccountDataScreen()),
  GoRoute(
      path: '/account-deactivation',
      builder: (context, state) => const AccountDeactivationScreen()),
  GoRoute(
      path: '/account-deletion',
      builder: (context, state) => const AccountDeletionScreen()),

  // Provider shell (bottom-nav: Dashboard / Bookings / Portfolio / Messages / Profile)
  GoRoute(
      path: '/provider', builder: (context, state) => const ProviderShell()),
  GoRoute(
      path: '/statistics',
      builder: (context, state) => const StatisticsScreen()),
  GoRoute(
      path: '/my-services',
      builder: (context, state) => const MyServicesScreen()),
  GoRoute(
      path: '/portfolio',
      builder: (context, state) => const ProviderPortfolioScreen()),
  GoRoute(
      path: '/add-service',
      builder: (context, state) => const AddServiceScreen()),
  GoRoute(
    path: '/edit-service/:id',
    builder: (context, state) =>
        EditServiceScreen(serviceId: state.pathParameters['id']!),
  ),
  GoRoute(
      path: '/upload-portfolio',
      builder: (context, state) => const UploadPortfolioScreen()),
  GoRoute(
      path: '/calendar', builder: (context, state) => const CalendarScreen()),
  GoRoute(
      path: '/booking-requests',
      builder: (context, state) => const BookingRequestsScreen()),
  GoRoute(
      path: '/active-jobs',
      builder: (context, state) => const ActiveJobsScreen()),
  GoRoute(
      path: '/completed-jobs',
      builder: (context, state) => const CompletedJobsScreen()),
  GoRoute(
      path: '/earnings', builder: (context, state) => const EarningsScreen()),
  GoRoute(
      path: '/withdrawal-history',
      builder: (context, state) => const WithdrawalHistoryScreen()),
  GoRoute(
      path: '/verification-status',
      builder: (context, state) => const VerificationStatusScreen()),
  GoRoute(
      path: '/provider-onboarding',
      builder: (context, state) => const ProviderOnboardingScreen()),
  GoRoute(
      path: '/provider-badges',
      builder: (context, state) => const BadgesScreen()),

  // Shared across personas
  GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen()),
  GoRoute(
    path: '/reviews/:providerId',
    builder: (context, state) =>
        ReviewsScreen(providerId: state.pathParameters['providerId']!),
  ),
];

/// The app's canonical [GoRouter], built from [appRoutes].
final GoRouter appRouter =
    GoRouter(initialLocation: '/splash', routes: appRoutes);

final _protectedPrefixes = <String>[
  '/client',
  '/provider',
  '/booking',
  '/favorites',
  '/chat',
  '/payments',
  '/file-report',
  '/my-reports',
  '/write-review',
  '/edit-profile',
  '/change-password',
  '/activity-history',
  '/notification-preferences',
  '/privacy-settings',
  '/application-preferences',
  '/security-activity',
  '/account-data',
  '/account-deactivation',
  '/account-deletion',
];

GoRouter createAuthenticatedRouter(AuthController auth) => GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final path = state.uri.path;
        final protected =
            _protectedPrefixes.any((prefix) => path.startsWith(prefix));
        if (protected && auth.status != AuthStatus.authenticated) {
          return '/login';
        }
        if (path == '/login' && auth.isClient) return '/client';
        if (path == '/login' && auth.isProvider) return '/provider';
        return null;
      },
      routes: appRoutes,
    );
