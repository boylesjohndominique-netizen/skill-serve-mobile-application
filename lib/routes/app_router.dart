import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/booking/models/booking_model.dart';

// Auth
import '../features/auth/views/splash_screen.dart';
import '../features/auth/views/onboarding_screen.dart';
import '../features/auth/views/welcome_screen.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/auth/views/otp_verification_screen.dart';
import '../features/auth/views/google_registration_screen.dart';
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
import '../features/booking/views/reschedule_booking_screen.dart';

// Profile
import '../features/profile/views/edit_profile_screen.dart';
import '../features/profile/views/change_password_screen.dart';
import '../features/profile/views/account_data_screen.dart';
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
import '../features/support/views/new_ticket_screen.dart';
import '../features/support/views/support_tickets_screen.dart';
import '../features/support/views/ticket_detail_screen.dart';
import '../features/reviews/views/my_reviews_screen.dart';
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
import '../features/provider/views/availability_screen.dart';

// Booking (provider views)
import '../features/provider/views/calendar_screen.dart';
import '../features/provider/views/booking_requests_screen.dart';
import '../features/provider/views/active_jobs_screen.dart';
import '../features/provider/views/completed_jobs_screen.dart';

// Identity
import '../features/identity/views/identity_verification_screen.dart';

// Provider earnings
import '../features/provider/views/commissions_screen.dart';
import '../features/provider/views/earnings_screen.dart';
import '../features/provider/views/gcash_details_screen.dart';
import '../features/provider/views/verification_status_screen.dart';

// Settings
import '../features/settings/views/about_screen.dart';
import '../features/settings/views/contact_screen.dart';
import '../features/settings/views/terms_screen.dart';
import '../features/settings/views/privacy_screen.dart';
import '../features/settings/views/community_guidelines_screen.dart';
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
      path: '/google-register',
      builder: (context, state) => const GoogleRegistrationScreen()),
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
  GoRoute(path: '/community-guidelines', builder: (context, state) => const CommunityGuidelinesScreen()),

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
    path: '/reschedule-booking/:id',
    builder: (context, state) =>
        RescheduleBookingScreen(bookingId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/booking-details/:id',
    builder: (context, state) =>
        BookingDetailsScreen(bookingId: state.pathParameters['id']!),
  ),
  GoRoute(
      path: '/favorites', builder: (context, state) => const FavoritesScreen()),
  GoRoute(
    // Messaging is booking-scoped, so the thread is addressed by booking id.
    path: '/chat-conversation/:bookingId',
    builder: (context, state) =>
        ChatConversationScreen(bookingId: state.pathParameters['bookingId']!),
  ),
  GoRoute(
      path: '/payments', builder: (context, state) => const PaymentsScreen()),
  GoRoute(
    // A payment lives on its booking, so it is addressed by the booking id.
    path: '/payment-details/:bookingId',
    builder: (context, state) =>
        PaymentDetailsScreen(bookingId: state.pathParameters['bookingId']!),
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
      path: '/my-reviews', builder: (context, state) => const MyReviewsScreen()),
  GoRoute(
      path: '/support/tickets',
      builder: (context, state) => const SupportTicketsScreen()),
  GoRoute(
      path: '/support/new', builder: (context, state) => const NewTicketScreen()),
  GoRoute(
    path: '/support/tickets/:ticketId',
    builder: (context, state) =>
        TicketDetailScreen(ticketId: state.pathParameters['ticketId']!),
  ),
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
      path: '/availability',
      builder: (context, state) => const AvailabilityScreen()),
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
      path: '/commissions',
      builder: (context, state) => const CommissionsScreen()),
  GoRoute(
      path: '/gcash-details',
      builder: (context, state) => const GcashDetailsScreen()),
  GoRoute(
      path: '/verification-status',
      builder: (context, state) => const VerificationStatusScreen()),
  GoRoute(
      path: '/provider-onboarding',
      builder: (context, state) => const ProviderOnboardingScreen()),
  GoRoute(
      path: '/verify-email',
      builder: (context, state) => OtpVerificationScreen(
        email: state.uri.queryParameters['email'] ?? '',
      )),
  GoRoute(
      path: '/provider-badges',
      builder: (context, state) => const BadgesScreen()),

  // Shared across personas
  GoRoute(
    // Identity is identity: customers and providers submit the same National
    // ID through the same screen. `next` is where registration sends them
    // afterwards.
    path: '/identity-verification',
    builder: (context, state) =>
        IdentityVerificationScreen(next: state.uri.queryParameters['next']),
  ),
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

/// Screens either role may use once signed in.
const _sharedSignedIn = <String>{
  'notifications',
  'identity-verification',
  'chat-conversation',
  'booking-details',
  'file-report',
  'my-reports',
  'support',
  'edit-profile',
  'change-password',
  'activity-history',
  'notification-preferences',
  'privacy-settings',
  'application-preferences',
  'security-activity',
  'account-data',
  'account-deletion',
};

/// The customer and provider experiences are separate apps within the app:
/// different workflows, different permissions. Every route belongs to one of
/// them or is deliberately shared, and a signed-in user who reaches the other
/// role's route is sent to their own home.
///
/// Matched on the whole first path segment — `/provider-preview` is the guest
/// marketplace view, not a provider screen, so prefixes are not enough.
const _customerOnly = <String>{
  'client',
  'booking-form',
  'booking-confirmation',
  'booking-history',
  'reschedule-booking',
  'favorites',
  'payments',
  'payment-details',
  'write-review',
  'my-reviews',
};

const _providerOnly = <String>{
  'provider',
  'provider-onboarding',
  'booking-requests',
  'active-jobs',
  'completed-jobs',
  'calendar',
  'earnings',
  'commissions',
  'gcash-details',
  'my-services',
  'add-service',
  'edit-service',
  'availability',
  'portfolio',
  'upload-portfolio',
  'provider-badges',
  'verification-status',
  'statistics',
};

/// The marketplace: open to guests and customers. A provider runs their
/// business from the provider app and does not shop as a customer.
///
/// Two read-only pages stay open to providers too, because they are how a
/// provider sees themselves as customers do: `/provider-preview/:id` (the
/// public profile, with no booking action for a provider) and
/// `/reviews/:providerId`.
const _marketplace = <String>{
  'browse',
  'categories',
  'search',
  'service-details',
  'provider-profile',
  'portfolio-gallery',
};

/// Screens that only make sense before signing in.
const _signedOutOnly = <String>{'', 'login', 'register', 'welcome', 'onboarding'};

String _firstSegment(String path) {
  final segments = Uri.parse(path).pathSegments;
  return segments.isEmpty ? '' : segments.first;
}

/// Where a user should be sent from [path], or null to let them through.
///
/// Signed out: only the routes that need an account send them to login.
/// Signed in: the other role's routes, and the sign-in screens, send them to
/// their own home.
@visibleForTesting
String? redirectFor({
  required String path,
  required bool isClient,
  required bool isProvider,
}) {
  final segment = _firstSegment(path);
  final signedIn = isClient || isProvider;

  if (!signedIn) {
    final protected = _customerOnly.contains(segment) ||
        _providerOnly.contains(segment) ||
        _sharedSignedIn.contains(segment);
    return protected ? '/login' : null;
  }

  // The splash screen decides for itself once the session is restored.
  if (segment == 'splash') return null;

  final home = isProvider ? '/provider' : '/client';
  if (_signedOutOnly.contains(segment)) return home;
  if (isProvider && (_customerOnly.contains(segment) || _marketplace.contains(segment))) {
    return home;
  }
  if (isClient && _providerOnly.contains(segment)) return home;
  return null;
}

GoRouter createAuthenticatedRouter(AuthController auth) => GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final path = state.uri.path;

        // A registration that hasn't been verified by OTP yet must never
        // reach any other screen: keep the user on /verify-email until the
        // code is confirmed. (Also guards against system back navigation.)
        if (auth.requiresEmailVerification) {
          if (path == '/verify-email') return null;
          // Carry the address so the OTP screen can label itself and
          // resend, even when the redirect came from an unrelated route.
          final email = auth.pendingEmail;
          return email == null || email.isEmpty
              ? '/verify-email'
              : '/verify-email?email=${Uri.encodeComponent(email)}';
        }

        final signedIn = auth.status == AuthStatus.authenticated;
        return redirectFor(
          path: path,
          isClient: signedIn && auth.isClient,
          isProvider: signedIn && auth.isProvider,
        );
      },
      routes: appRoutes,
    );
