import 'package:go_router/go_router.dart';

import '../data/mock/mock_data.dart';
import '../models/booking_model.dart';

// Guest
import '../views/guest/splash_screen.dart';
import '../views/guest/onboarding_screen.dart';
import '../views/guest/welcome_screen.dart';
import '../views/guest/login_screen.dart';
import '../views/guest/register_screen.dart';
import '../views/guest/forgot_password_screen.dart';
import '../views/guest/browse_services_screen.dart';
import '../views/guest/categories_screen.dart';
import '../views/guest/search_screen.dart';
import '../views/guest/provider_preview_screen.dart';
import '../views/guest/about_screen.dart';
import '../views/guest/contact_screen.dart';
import '../views/guest/terms_screen.dart';
import '../views/guest/privacy_screen.dart';

// Client
import '../views/client/client_shell.dart';
import '../views/client/provider_profile_screen.dart';
import '../views/client/service_details_screen.dart';
import '../views/client/portfolio_gallery_screen.dart';
import '../views/client/booking_form_screen.dart';
import '../views/client/booking_confirmation_screen.dart';
import '../views/client/booking_history_screen.dart';
import '../views/client/booking_details_screen.dart';
import '../views/client/favorites_screen.dart';
import '../views/client/chat_conversation_screen.dart';
import '../views/client/edit_profile_screen.dart';
import '../views/client/change_password_screen.dart';
import '../views/client/help_center_screen.dart';
import '../views/client/payments_screen.dart';
import '../views/client/payment_details_screen.dart';
import '../views/client/file_report_screen.dart';
import '../views/client/my_reports_screen.dart';
import '../views/client/write_review_screen.dart';

// Provider
import '../views/provider/provider_shell.dart';
import '../views/provider/statistics_screen.dart';
import '../views/provider/my_services_screen.dart';
import '../views/provider/add_service_screen.dart';
import '../views/provider/edit_service_screen.dart';
import '../views/provider/upload_portfolio_screen.dart';
import '../views/provider/calendar_screen.dart';
import '../views/provider/booking_requests_screen.dart';
import '../views/provider/active_jobs_screen.dart';
import '../views/provider/completed_jobs_screen.dart';
import '../views/provider/earnings_screen.dart';
import '../views/provider/withdrawal_history_screen.dart';
import '../views/provider/verification_status_screen.dart';
import '../views/provider/portfolio_screen.dart';
import '../views/provider/provider_onboarding_screen.dart';
import '../views/provider/badges_screen.dart';

// Shared
import '../views/shared/notifications_screen.dart';
import '../views/shared/reviews_screen.dart';

/// Central route table. Grouped by persona to mirror lib/views/ — Guest,
/// Client, and Provider each own their sub-tree, with a few screens
/// (Notifications, Reviews, Booking Details, static info pages) shared
/// across personas via top-level routes.
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),

    // Guest-accessible marketplace browsing (also reused as push destinations for Client)
    GoRoute(path: '/browse', builder: (context, state) => const BrowseServicesScreen()),
    GoRoute(path: '/categories', builder: (context, state) => const CategoriesScreen()),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/provider-preview/:id',
      builder: (context, state) => ProviderPreviewScreen(providerId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
    GoRoute(path: '/contact', builder: (context, state) => const ContactScreen()),
    GoRoute(path: '/terms', builder: (context, state) => const TermsScreen()),
    GoRoute(path: '/privacy', builder: (context, state) => const PrivacyScreen()),

    // Client shell (bottom-nav: Home / Search / Bookings / Chat / Profile)
    GoRoute(path: '/client', builder: (context, state) => const ClientShell()),
    GoRoute(
      path: '/provider-profile/:id',
      builder: (context, state) => ProviderProfileScreen(providerId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/service-details/:id',
      builder: (context, state) => ServiceDetailsScreen(serviceId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/portfolio-gallery/:id',
      builder: (context, state) => PortfolioGalleryScreen(providerId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/booking-form/:providerId',
      builder: (context, state) => BookingFormScreen(providerId: state.pathParameters['providerId']!),
    ),
    GoRoute(
      path: '/booking-confirmation',
      builder: (context, state) => BookingConfirmationScreen(booking: state.extra as BookingModel),
    ),
    GoRoute(path: '/booking-history', builder: (context, state) => const BookingHistoryScreen()),
    GoRoute(
      path: '/booking-details/:id',
      builder: (context, state) => BookingDetailsScreen(bookingId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
    GoRoute(
      path: '/chat-conversation/:id',
      builder: (context, state) => ChatConversationScreen(conversationId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/payments', builder: (context, state) => const PaymentsScreen()),
    GoRoute(
      path: '/payment-details/:id',
      builder: (context, state) => PaymentDetailsScreen(paymentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/file-report',
      builder: (context, state) => FileReportScreen(bookingId: state.uri.queryParameters['bookingId']),
    ),
    GoRoute(path: '/my-reports', builder: (context, state) => const MyReportsScreen()),
    GoRoute(
      path: '/write-review/:bookingId',
      builder: (context, state) => WriteReviewScreen(bookingId: state.pathParameters['bookingId']!),
    ),
    GoRoute(path: '/edit-profile', builder: (context, state) => const EditProfileScreen()),
    GoRoute(path: '/change-password', builder: (context, state) => const ChangePasswordScreen()),
    GoRoute(path: '/help-center', builder: (context, state) => const HelpCenterScreen()),

    // Provider shell (bottom-nav: Dashboard / Bookings / Portfolio / Messages / Profile)
    GoRoute(path: '/provider', builder: (context, state) => const ProviderShell()),
    GoRoute(path: '/statistics', builder: (context, state) => const StatisticsScreen()),
    GoRoute(path: '/my-services', builder: (context, state) => const MyServicesScreen()),
    GoRoute(path: '/portfolio', builder: (context, state) => const ProviderPortfolioScreen()),
    GoRoute(path: '/add-service', builder: (context, state) => const AddServiceScreen()),
    GoRoute(
      path: '/edit-service/:id',
      builder: (context, state) => EditServiceScreen(serviceId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/upload-portfolio', builder: (context, state) => const UploadPortfolioScreen()),
    GoRoute(path: '/calendar', builder: (context, state) => const CalendarScreen()),
    GoRoute(path: '/booking-requests', builder: (context, state) => const BookingRequestsScreen()),
    GoRoute(path: '/active-jobs', builder: (context, state) => const ActiveJobsScreen()),
    GoRoute(path: '/completed-jobs', builder: (context, state) => const CompletedJobsScreen()),
    GoRoute(path: '/earnings', builder: (context, state) => const EarningsScreen()),
    GoRoute(path: '/withdrawal-history', builder: (context, state) => const WithdrawalHistoryScreen()),
    GoRoute(path: '/verification-status', builder: (context, state) => const VerificationStatusScreen()),
    GoRoute(path: '/provider-onboarding', builder: (context, state) => const ProviderOnboardingScreen()),
    GoRoute(path: '/provider-badges', builder: (context, state) => const BadgesScreen()),
    GoRoute(
      path: '/provider-profile-preview',
      builder: (context, state) => ProviderProfileScreen(
        providerId: MockData.providers
            .firstWhere(
              (p) => p.user.id == MockData.currentProvider.id,
              orElse: () => MockData.providers.first,
            )
            .id,
      ),
    ),

    // Shared across personas
    GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    GoRoute(
      path: '/reviews/:providerId',
      builder: (context, state) => ReviewsScreen(providerId: state.pathParameters['providerId']!),
    ),
  ],
);

