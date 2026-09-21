# SkillServe Agent Guide

## Product Scope

SkillServe is a monolith application with a Laravel backend and Flutter mobile frontend.
The backend serves the REST API; the Flutter app is the client-facing mobile interface
for guest, client, and service-provider experiences. Administrative approval, moderation,
verification decisions, platform management, and system control remain on the admin web side.

**No mock data.** All development uses the live Laravel REST API directly. Every service
calls the backend through `ApiClient` with Sanctum bearer tokens. If an endpoint is not
yet implemented on the backend, the service throws `UnsupportedError` — never return
placeholder or fake data.

## Source Of Truth

Use `SkillServe_User_Mobile_Functionalities_Flutter.pdf` as the product requirements
source. The app must only be changed for functionality that is already implemented in the
repository. Do not build deferred PDF items simply to make the requirements matrix look
complete.

## Architecture

- **Backend**: Laravel (PHP) — REST API with Sanctum bearer token authentication.
- **Frontend**: Flutter (Dart) — mobile client consuming `/api/client/v1/*` endpoints.
- **Monolith repo**: Both backend and frontend live in the same repository.
- **API docs**: `api-docs/` contains OpenAPI spec and per-module endpoint documentation.
- **No mock data layer**: Services call the API directly. `AppConfig.useMockData` is removed.

## Implemented PDF Scope

- Authentication: registration, login, logout, forgot-password request, role-based landing, persistent local sessions with expiry, and account status data display.
- User profile: view/edit profile data, password change, profile photo add/change/remove, account status messaging, and dedicated booking/report activity history.
- Service discovery: browse, search, categories, service details, featured services, and provider discovery/profile details.
- Provider discovery: browse and search verified providers, filter by category, minimum rating, featured recognition, bookable availability and the weekday a provider works, and view a provider's skills, experience, portfolio, services, ratings, badges and verification status.
- Search and personalized discovery: one search box over services and providers, suggestions drawn from categories and live results, locally persisted and clearable recent searches, and the featured and top-rated provider rails.
- Booking: create (with the job address and contact number), confirm, view history/details, status display, cancellation with a reason, and report/dispute entry.
- Provider bookings: providers list the bookings placed with them, see the customer's name, number and job address, and accept, decline (with a reason), start and complete each job. Every status change notifies the other party in the notification feed.
- Reviews: submit a rating/review for a completed booking, edit it later, view your own review history (with moderation state), and read a provider's published reviews.
- Messaging: a booking-scoped inbox (one thread per booking) with search, conversation history, send with optimistic delivery and retry, read receipts, per-thread and total unread counts on the Messages tab, and realtime receive over the existing Reverb channel.
- Notifications: feed with category filters (bookings, messages, services, announcements, system), per-item and mark-all read state, tap-through to the booking, conversation, ticket or service a notification is about, admin announcements shown as their own category, and realtime delivery while the app is open.
- Provider account: provider onboarding, provider profile, verification status, portfolio, and recognition badges.
- Provider services: create, list, edit, approval/status display, and availability/calendar UI.
- Provider availability: providers publish weekly hours and a "taking new bookings" flag; clients see them on the public profile, discovery filters by them, and the booking flow refuses times outside a published window.
- Reports: report the other party on one of your bookings (the API derives who that is from the booking), and follow each case's status and the support team's outcome. Customers and providers can both file.
- Disputes: either party raises a dispute on a job that is in progress or completed, once per booking. The booking moves to `disputed`, both parties are notified, and the case appears in the admin console's dispute queue. The app shows its status and resolution.
- Support: customers raise tickets, follow the thread with staff, and reply until the ticket is resolved.
- Settings and policies: persisted notification, privacy, and application preferences, profile/password settings, terms, privacy policy, and help center.
- Mobile security: persisted session expiry, protected-route guards, unauthorized access redirects, and security activity notifications.
- Logout: confirmed logout from client and provider profile screens.

## Deferred Scope

The following PDF items are not currently implemented and must not be added unless the user
explicitly requests them as a new feature:

- Production-grade secure token storage and server-side authorization hardening.
- Account suspension/ban workflows beyond displaying the existing status.
- Review reporting.
- Closed-app push notifications (FCM/APNs): the owner chose realtime over the Laravel backend rather than Firebase, so notifications arrive live only while the app is open and are waiting in the feed otherwise.
- Account deactivation: an account is either active or deleted.
- Message reporting (reports are filed against the other party on a booking, not against a message).
- Dispute evidence upload: the API accepts a written reason only.
- Support tickets for provider accounts: `/support/tickets` is restricted to customers, so the provider Help Center points at the contact details instead.
- Presence ("online"/"active now") and typing indicators: there is no presence infrastructure, so the chat screens must not display either.
- Admin announcements and true targeted/push notifications.
- Provider information-request response and provider restriction workflows.
- Device-level biometric authentication and server-side authorization enforcement.

## Engineering Rules

- Preserve the existing MVC-style structure: models, services, `ChangeNotifier` controllers, and views.
- **No mock data.** All services call the Laravel API directly through `ApiClient`.
- Read `api-docs/README.md`, `api-docs/MODULES.md`, and the relevant `api-docs/modules/*.md` files before adding an endpoint.
- Use only the documented client surface (`/api/client/v1/*`) for mobile customer flows; never use admin endpoints for mobile users.
- Send Sanctum bearer tokens through `ApiClient`/`TokenStorage`, handle documented `401` responses by clearing the session, and never store passwords.
- If the API docs do not define a client endpoint, throw `UnsupportedError` in the service layer — do not invent endpoints or return fake data.
- Controllers must catch service errors gracefully and return empty states instead of crashing.
- Reuse existing theme tokens, widgets, status badges, and route conventions.
- Do not add admin-only functionality to the mobile app.
- Before editing, inspect existing routes, controllers, services, and models for the module.
- Add or update tests for behavior that can be verified.
- Run `flutter analyze` and the relevant Flutter tests before reporting completion.

## Module Completion Checklist

- Requirement mapped to an implemented screen, controller, service, model, or route.
- Service calls the live API — no mock data or placeholder returns.
- Loading, empty, success, and error states are handled where the module supports them.
- Protected actions require real authentication via Sanctum bearer tokens.
- No deferred module was introduced as a side effect.
- `flutter analyze` passes.
- Relevant widget tests pass at phone-sized layouts.

## API Integration Status

- Client authentication: `/api/client/v1/auth/login`, `register`, `register-provider`, `verify-otp`, `resend-otp`, `google`, `logout`, `me`, `refresh`, `forgot-password`, `change-password`.
- Registration (client and provider) issues a 6-digit email OTP; `verify-otp` must be called before login works. Google Sign-In exchanges a mobile ID token for a session and skips OTP.
- Client notifications: inbox, read, read-all, unread-count.
- Account data: `GET /api/client/v1/auth/me/data-export` returns the account's own data (profile, preferences, provider profile, bookings, reviews, reports, support tickets); the app copies it to the clipboard as JSON. `DELETE /api/client/v1/auth/me` takes the password (and an optional reason), refuses while any booking is pending/confirmed/active/disputed, then soft-deletes the account and revokes every token. An administrator can restore it from Data Management.
- Client reviews: `GET /api/client/v1/reviews` (own history), `POST` (completed booking, once) and `PATCH /api/client/v1/reviews/{review}` (edit).
- Client reports: `GET`/`POST /api/client/v1/reports` and `GET /api/client/v1/reports/{report}`. `POST` takes `booking_id`, `reason` (enum) and `description`; the reported account is the booking's other party, so the caller must have been on it. The reporter sees status and outcome, never the moderators' investigation notes.
- Booking disputes: `PATCH /api/client/v1/bookings/{booking}/dispute` (either party, once, on an `active` or `completed` booking) and `GET /api/client/v1/disputes`. Raising one sets `dispute_status = pending`, which is what hands the case to the admin dispute queue.
- Client support: `GET`/`POST /api/client/v1/support/tickets`, `GET .../{ticket}` and `POST .../{ticket}/replies`. Customer accounts only; a resolved ticket refuses new replies.
- Conversations: `GET /api/client/v1/conversations` (the Messages inbox — bookings with at least one message, newest first, each with its counterpart, last message and unread count; reading it marks nothing read) and `GET /api/client/v1/conversations/unread-count` for the tab badge.
- Booking messages: `GET`/`POST /api/client/v1/bookings/{booking}/messages`. Messaging is booking-scoped — a booking *is* the conversation, so threads are addressed by booking id and there is no way to message a provider before booking them. `GET` marks the caller's received messages in that thread as read; `POST` accepts an `Idempotency-Key`.
- Realtime messages: a new message broadcasts `client.message.created` on the receiver's private `App.Models.User.{id}` channel, carrying `booking_id` and the message. It is not gated by the "Messages" notification setting, because muting the alert must not stop an open conversation from updating; the muteable alert is a separate notification.
- Client marketplace: categories, providers, services. Provider and service lists accept `search`, `category_id`, `subcategory_id` and `min_rating`; provider lists also accept `featured`, `available` (taking bookings and has a service that can be booked online) and `available_day` (0 = Sunday), plus `sort`/`direction`.
- Provider availability: `GET`/`PUT /api/client/v1/provider/availability` — the signed-in provider's weekly hours and `is_accepting_bookings`. `PUT` replaces the whole schedule; an empty array means no published hours, which leaves booking times unrestricted.
- Client bookings: list, create, get, cancel. Creation accepts `service_address` and `contact_phone` alongside `client_notes` and `payment_method`, and an `Idempotency-Key` header makes a retried submit return the booking already created.
- Provider bookings: `GET /api/client/v1/provider/bookings` and `/{booking}`, plus `PATCH .../{booking}/confirm|decline|start|complete`. The lifecycle is pending → confirmed → active → completed, with decline cancelling a pending request; a transition from the wrong status returns 422. The provider payload carries the customer's contact details instead of a provider block, which is why provider screens read this endpoint rather than the customer's.
- Profile reads use `GET /api/client/v1/auth/me`. Profile update has no documented client endpoint — throws `UnsupportedError`.
- Endpoints without client documentation throw `UnsupportedError` — never return mock data.
