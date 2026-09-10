# SkillServe Mobile Agent Guide

## Product Scope

This repository is the Flutter user-side application for SkillServe. It serves guest,
client, and service-provider experiences. Administrative approval, moderation,
verification decisions, platform management, and system control remain outside this app.

The current implementation is a frontend prototype. Mock data remains active while
documented Laravel API calls are wired behind the service layer. Do not describe mock
behavior as production authentication or persistence.

## Source Of Truth

Use `SkillServe_User_Mobile_Functionalities_Flutter.pdf` as the product requirements
source. The app must only be changed for functionality that is already implemented in the
repository. Do not build deferred PDF items simply to make the requirements matrix look
complete.

## Implemented PDF Scope

- Authentication: registration, login, logout, forgot-password request, role-based landing, persistent local sessions with expiry, and account status data display.
- User profile: view/edit profile data, password change, profile photo add/change/remove, account status messaging, and dedicated booking/report activity history.
- Service discovery: browse, search, categories, service details, featured services, and provider discovery/profile details.
- Booking: create, confirm, view history/details, status display, cancellation, and report/dispute entry.
- Reviews: submit rating/review and view published provider reviews.
- Messaging: conversation list, conversation history, send message, and receive mock messages.
- Notifications: notification feed, booking/service/system notification types, read state, and history.
- Provider account: provider onboarding, provider profile, verification status, portfolio, and recognition badges.
- Provider services: create, list, edit, approval/status display, and availability/calendar UI.
- Reports/disputes: submit a complaint/dispute and view report status/history.
- Settings and policies: persisted notification, privacy, and application preferences, profile/password settings, terms, privacy policy, and help center.
- Mobile security: persisted session expiry, protected-route guards, unauthorized access redirects, and security activity notifications.
- Logout: confirmed logout from client and provider profile screens.

## Deferred Scope

The following PDF items are not currently implemented and must not be added unless the user
explicitly requests them as a new feature:

- Production-grade secure token storage and server-side authorization hardening.
- Account suspension/ban workflows beyond displaying the existing mock status.
- Review reporting and user-submitted review history.
- Message reporting.
- Admin announcements and true targeted/push notifications.
- Provider information-request response and provider restriction workflows.
- Dispute evidence upload and dispute detail/update screens.
- Support ticket creation, replies, ticket lists, and ticket details.
- Search suggestions and persisted/clearable recent searches.
- Device-level biometric authentication and server-side authorization enforcement.
- Account-data export/view, account deactivation, and account deletion requests.

## Engineering Rules

- Preserve the existing MVC-style structure: models, services, `ChangeNotifier` controllers, and views.
- Keep mock data behind services; do not put API calls directly in screens.
- Keep `AppConfig.useMockData` as the mock/live switch.
- Read `api-docs/README.md`, `api-docs/MODULES.md`, and the relevant `api-docs/modules/*.md` files before adding an endpoint.
- Use only the documented client surface (`/api/client/v1/*`) for mobile customer flows; never use admin endpoints for mobile users.
- Keep documented live API calls in services behind `if (!AppConfig.useMockData)`; mock branches remain the default.
- Send Sanctum bearer tokens through `ApiClient`/`TokenStorage`, handle documented `401` responses by clearing the session, and never store passwords.
- If the API docs do not define a client endpoint, do not invent one. Leave an explicit service-layer `UnsupportedError` or comment and keep the mock path active.
- Do not remove mock data until live API mode has been explicitly enabled and verified.
- Reuse existing theme tokens, widgets, status badges, and route conventions.
- Do not add admin-only functionality to the mobile app.
- Before editing, inspect existing routes, controllers, services, and mock data for the module.
- Add or update tests for behavior that can be verified without a backend.
- Run `flutter analyze` and the relevant Flutter tests before reporting completion.

## Module Completion Checklist

- Requirement mapped to an implemented screen, controller, service, model, or route.
- Existing mock behavior remains navigable.
- Loading, empty, success, and error states are handled where the module already supports them.
- Protected-looking actions do not claim real authorization while the app is mock-backed.
- No deferred module was introduced as a side effect.
- `flutter analyze` passes.
- Relevant widget tests pass at phone-sized layouts.

## API Integration Status

- Client authentication API scaffolding is mapped to `/api/client/v1/auth/login`, `register`, `logout`, `me`, `refresh`, `forgot-password`, and `change-password`.
- Client notifications API scaffolding is mapped to the documented inbox, read, read-all, and unread-count endpoints.
- Profile reads use the documented client `auth/me` endpoint when live mode is enabled; profile update and preference persistence have no documented client endpoints and remain mock/local until the backend documents them.
