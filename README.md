# SkillServe Mobile — Clients and Service Providers

Flutter app for **Bridging Service Accessibility and Talent Visibility Through an Integrated
Skills Marketplace and Service Management Platform** (SkillServe).

It serves guests (browsing), **clients** (discover, book, pay the provider off-platform, review,
chat, dispute, support) and **service providers** (profile, verification, services,
availability, jobs, earnings). Administration — approvals, moderation, verification decisions,
settings — happens in the SkillServe admin web. The app talks only to the Laravel REST API
(`/api/client/v1/*`) and Reverb WebSockets; it never touches the database directly.

Requirements: `SkillServe_User_Mobile_Functionalities_Flutter.pdf`. Open work:
`PENDING_FIXES.md`. Test plan: `TEST_PLAN.md`. API reference: `api-docs/` (generated from the
backend's OpenAPI spec).

## Tech stack

- **Flutter** (stable) + **Dart**, Material 3, Android as the release target
- **provider** — `ChangeNotifier` controllers per feature
- **go_router** — one route table with role guards (`lib/routes/app_router.dart`)
- **dio** — REST client with automatic access-token refresh (`lib/core/services/api_client.dart`)
- **web_socket_channel** — a small Reverb (Pusher protocol) client for private and presence
  channels (`lib/core/services/realtime_client.dart`)
- **flutter_secure_storage** — session tokens in the Android Keystore / iOS Keychain
- **shared_preferences** — cached account, preferences, recent searches
- **workmanager** + **flutter_local_notifications** — notifications while the app is closed
  (no Firebase; see below)
- **google_sign_in**, **image_picker**, **connectivity_plus**, **intl**
- **google_fonts**, **hugeicons**, **flutter_animate**, **shimmer**, **cached_network_image**,
  **flutter_screenutil**, **responsive_framework** — visuals and layout

## Getting started

```bash
flutter pub get
flutter run --dart-define-from-file=env/local.json        # local Docker backend
flutter run --dart-define-from-file=env/production.json   # Render
```

Without a define file the app targets production
(`https://skillserve-web-backend.onrender.com/api`). Other overrides: `API_BASE_URL`,
`REVERB_APP_KEY` (must match the backend's `REVERB_APP_KEY`), `REVERB_HOST`, `REVERB_PORT`,
`REVERB_SCHEME`, `GOOGLE_WEB_CLIENT_ID` — see `lib/core/config/app_config.dart`. Google sign-in
and mail setup are in `SETUP_CREDENTIALS.md`.

### Running Flutter from WSL

The Windows Flutter SDK cannot be called directly from WSL (its shell entry point has Windows
line endings). Use the wrapper, which hands the command to Windows:

```bash
tool/wsl-flutter.sh analyze
tool/wsl-flutter.sh test
tool/wsl-flutter.sh test test/booking_test.dart
```

## Project structure

```
lib/
├── core/
│   ├── config/      # AppConfig — API base URL, Reverb, timeouts (compile-time defines)
│   ├── constants/   # Colors, text styles, sizes, icons
│   ├── services/    # ApiClient, TokenStorage, RealtimeClient, BackgroundNotifications
│   ├── theme/       # Light/dark ThemeData built from the constants
│   ├── utils/       # Validators, formatters, API error messages
│   └── widgets/     # Shared buttons, cards, inputs, feedback, navigation, misc
├── features/        # One folder per module, each with controllers/ models/ services/ views/
│   ├── auth/            # Registration (OTP), login, Google sign-in, password recovery
│   ├── marketplace/     # Browse, search, filters, provider profiles, favorites
│   ├── booking/         # Booking form, history, details, reschedule, cancel
│   ├── payments/        # Payment status per booking (settled off-platform)
│   ├── provider/        # Provider profile, verification, services, availability, jobs, earnings
│   ├── messaging/       # Booking conversations, presence and typing
│   ├── notifications/   # Feed, realtime banners, unread badge
│   ├── reviews/         # Write, edit, view, report reviews
│   ├── reports/         # Reports and disputes (with evidence)
│   ├── support/         # Support tickets and replies
│   ├── profile/         # Edit profile, password, account data export, deletion
│   └── settings/        # Preferences, privacy, help center, policies
├── routes/          # app_router.dart — routes and the customer/provider/shared role split
└── main.dart        # Providers, theme, router, background notification setup
```

Tests are in `test/` (models, controllers, routing guards, token storage, presence, background
checks, layout overflow sweeps): `tool/wsl-flutter.sh test`.

## How key parts work

- **Two apps in one.** `redirectFor` in `app_router.dart` gives customers and providers separate
  shells and blocks each from the other's routes; a few screens (notifications, chat, booking
  details, reports, support, account) are shared on purpose.
- **Sessions.** A short-lived access token is renewed from a rotating refresh token, one refresh
  at a time (reusing a rotated token revokes the session). Users stay signed in until they sign
  out or the server ends the session.
- **Realtime.** Notifications and chat messages arrive over Reverb on the user's private channel;
  each conversation also joins a presence channel for "In this chat" and "typing…". Polling is the
  fallback while the socket is down.
- **Closed-app notifications (no Firebase).** After sign-in the app gets a read-only background
  token; Android WorkManager checks `GET /notifications/background` about every 15 minutes and
  posts system notifications. It is not instant, and a force-stopped app gets nothing until it is
  opened again.
- **Payments.** SkillServe records payments but does not process them: the provider confirms
  "Payment received" on a completed job, and admins can record refunds.
- **Accounts are active or deleted.** There is no deactivation state; self-service deletion is a
  soft delete an administrator can restore (see `TEST_PLAN.md` → design decisions).

## Design system

Shares the admin web's identity: Ink Navy `#101828` (primary), Brass `#C9852E` (accent), Warm
Slate `#F5F4F1` (background); light and dark themes in `lib/core/theme/app_theme.dart`, built from
the tokens in `lib/core/constants/`. Typography: Space Grotesk (display/titles), Inter (body),
IBM Plex Mono (IDs, prices, timestamps). Statuses render through `StatusBadge`; trust signals
(verified provider, approved document) through `VerificationSeal`.

## Building a release

See `PENDING_FIXES.md` → H4 for the remaining release setup (application ID, signing key,
launcher icon). Then:

```bash
flutter build apk --release --dart-define-from-file=env/production.json
```
