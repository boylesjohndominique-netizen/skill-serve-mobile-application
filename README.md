# SkillLink Mobile — Users Side (Guest / Client / Service Provider)

Flutter frontend for **Bridging Service Accessibility and Talent Visibility Through an
Integrated Skills Marketplace and Service Management Platform**.

This is the **Users Side mobile app** — Guest browsing, Client booking, and Service
Provider management — matching the design language of the Admin Web Application.
**Frontend only.** No backend logic, authentication implementation, or database queries
are included; every data-dependent screen runs on realistic mock data behind a service
layer that's pre-shaped for a future Laravel REST API.

## Tech stack

- **Flutter** (stable) + **Dart**, Material 3
- **provider** — state management (MVC-style Controllers as `ChangeNotifier`s)
- **go_router** — declarative navigation across Guest / Client / Provider route trees
- **dio** — REST API client, ready to point at a Laravel backend
- **google_fonts** — Space Grotesk (display) + Inter (body), matching the admin web app
- **flutter_svg**, **lottie**, **cached_network_image**, **flutter_animate**, **shimmer** — visuals & motion
- **flutter_screenutil**, **responsive_framework** — responsive layout across phones/tablets
- **shared_preferences** — placeholder for session persistence
- **image_picker** — UI-only integration for the Upload Portfolio screen
- **intl** — currency/date formatting

## Getting started

```bash
flutter pub get
flutter run
```

> This deliverable includes the `lib/`, `assets/`, `pubspec.yaml`, and `analysis_options.yaml`
> — the platform folders (`android/`, `ios/`, etc.) are generated locally. If they don't
> already exist in your working copy, run once:
> ```bash
> flutter create . --platforms=android,ios
> ```
> then `flutter pub get` and `flutter run` as usual.

## Design system

Inherits the Admin Web Application's visual identity:

| Role | Color | Hex |
|---|---|---|
| Primary (structure, buttons on dark surfaces) | Ink Navy | `#101828` |
| Secondary / Accent (CTAs, active states) | Brass | `#C9852E` |
| Background | Warm Slate | `#F5F4F1` |
| Success / Warning / Error / Info | — | see `lib/core/constants/app_colors.dart` |

Both **light and dark themes** are implemented in `lib/core/theme/app_theme.dart`, built
entirely from the tokens in `lib/core/constants/` — change a color or type size there and
it propagates through every screen and component.

Typography: **Space Grotesk** for Display/Headline/Title, **Inter** for Body/Caption/Button/Label
— see `lib/core/constants/app_text_styles.dart`.

## Folder structure (MVC)

```
lib/
├── core/
│   ├── config/          # AppConfig — API base URL, mock-data toggle
│   ├── constants/        # Colors, text styles, sizes, asset paths
│   ├── theme/             # Light/dark ThemeData
│   ├── utils/              # Validators, formatters
│   └── widgets/             # Reusable components — buttons, cards, inputs, feedback, navigation, misc
├── models/                # Data classes mirroring the platform's DB tables
├── services/               # Placeholder REST API layer (AuthService, BookingService, etc.)
├── controllers/            # ChangeNotifier controllers — the "Controller" in MVC
├── data/mock/               # Mock/sample data used by services until the backend exists
├── views/
│   ├── guest/                # Splash, Onboarding, Welcome, Login, Register, Browse, etc.
│   ├── client/                 # Home, Search, Bookings, Chat, Profile, and their sub-screens
│   ├── provider/                 # Dashboard, Services, Portfolio, Calendar, Earnings, etc.
│   └── shared/                     # Screens reused across personas (Notifications, Reviews)
├── routes/                  # app_router.dart — single GoRouter route table
└── main.dart                 # Providers, theme, router, responsive wrapper
```

## Screens included

**Guest (14):** Splash, Onboarding, Welcome, Login, Register, Forgot Password, Browse
Services, Categories, Search, Provider Preview (login-gated booking), About, Contact,
Terms & Conditions, Privacy Policy.

**Client (18):** Home Dashboard, Search, Provider Profile, Service Details, Portfolio
Gallery, Booking Form, Booking Confirmation, Booking History, Booking Details, Favorite
Providers, Chat List, Chat Conversation, Settings, Edit Profile, Change Password, Help
Center — plus the shared Notifications and Reviews screens.

**Service Provider (18):** Dashboard, Statistics, My Services, Add/Edit Service,
Portfolio, Upload Portfolio, Calendar, Booking Requests, Active Jobs, Completed Jobs,
Earnings, Withdrawal History, Verification Status, Settings — plus the shared
Notifications and Reviews screens.

Client and Provider each have a bottom-navigation **shell** (`client_shell.dart`,
`provider_shell.dart`) hosting their five primary tabs; every other screen is reached via
`go_router` push navigation.

## Connecting to the Laravel backend

1. Update `lib/core/config/app_config.dart`:
   - Set `baseUrl` to your Laravel API root (e.g. `http://localhost:8000/api`).
   - Set `useMockData = false`.
2. Every method in `lib/services/*.dart` already contains a commented-out `Dio` call
   showing the exact endpoint and verb it expects (e.g. `POST /auth/login`,
   `PATCH /bookings/:id/cancel`) — uncomment and adapt once the matching Laravel route exists.
3. `lib/services/api_client.dart` has a placeholder spot for an auth interceptor — wire it
   to read a persisted token (e.g. via `shared_preferences`) once login issues real tokens.
4. Screens and controllers don't need to change: they call the service layer, which is the
   only place mock data vs. live API is decided.

## Reusable components (`lib/core/widgets/`)

- **buttons/** — `PrimaryButton` (with built-in loading state), `SecondaryButton`, `OutlinedAppButton`
- **cards/** — `ProviderCard`, `CategoryCard`, `BookingCard`, `ReviewCard`, `ProfileCard`
- **inputs/** — `AppTextField`, `AppSearchBar`
- **feedback/** — `EmptyState`, `ErrorState`, `LoadingState`, `ShimmerPlaceholder`/`ShimmerCardList`, `AppSnackbar`, `AppDialog`, `AppBottomSheet`
- **navigation/** — `AppBottomNav`, `AppDrawer`
- **misc/** — `RatingWidget`, `StatusBadge` (mirrors the admin web's verification "seal" concept), `SectionHeader`, `ImageCarousel`

## Notes for the team

- All mock data lives in `lib/data/mock/mock_data.dart` — regenerate or extend it freely;
  every controller/service reads from this single source.
- `AppConfig.useMockData` is the single switch between demo mode and live API mode.
- The design assumes phones as the primary target; `flutter_screenutil` and
  `responsive_framework` are wired in `main.dart` so tablet/landscape layouts scale
  sensibly without per-screen changes.
