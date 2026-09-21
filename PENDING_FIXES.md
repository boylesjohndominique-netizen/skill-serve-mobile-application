# Pending Fixes — SkillServe Mobile (Flutter)

Last full audit: 2026-09-21, against `SkillServe_User_Mobile_Functionalities_Flutter.pdf` and the
Laravel API. The master list — including backend, admin web and deployment — is
`web-project-bsit3blk3group6/PENDING_FIXES.md`; the IDs below are the same there. Items marked
**(needs backend)** need the API change listed in the master file first.

---

## Critical

Nothing open.

---

## High

Nothing open.

### Before the release build is handed out
1. Create the upload keystore and `android/key.properties` (`README.md` → "Building a release").
   Back up both.
2. Register the Android OAuth client for `com.skillserve.mobile` with the debug and release SHA-1
   fingerprints (`SETUP_CREDENTIALS.md`, section 2). Google sign-in fails until this is done.
3. Build with `flutter build apk --release --dart-define-from-file=env/production.json` and run the
   `TEST_PLAN.md` checks on a clean phone against the deployed backend.

---

## Medium

Nothing open.

---

## Low

Nothing open.

---

## Resolved on 2026-09-21

**Critical and High from the full audit:**
- **C1 — Verification upload.**
  - `VerificationService` sends multipart `POST /provider/verification`: up to 5 documents (JPG,
    PNG, PDF, 10 MB each) with a type and an optional note, with upload progress.
  - `VerificationUploadPanel` offers camera, gallery and PDF, and is used on Verification Status
    and in onboarding step 2.
  - The status screen shows the reviewer's reason or request and the documents sent; resubmitting
    is allowed when rejected or when more information is requested.
  - Tests: `test/verification_test.dart`.
- **C2 — Times.** `BookingModel.apiDateTime` sends UTC ISO-8601 for create and reschedule. The
  API reads provider hours in Asia/Manila.
- **C3 — Booking rules.** Before the client or provider confirms a cancellation, the cancel
  dialogs show the late-cancellation fee from `cancellation_policy`. A cancelled booking shows the
  reason and any fee recorded.
  - Maintenance mode shows a full-screen "under maintenance" notice (`MaintenanceGate`) that
    rechecks until the API is back.
- **C4 — Account status.**
  - A 403 carrying `meta.account` ends the session (`ApiClient.onSessionRevoked`).
  - The login screen explains the suspension or ban (`AccountRestrictionCard`); the reason and
    the end date appear when set.
  - Settings shows an account status card for both roles, including a provider suspension.
  - Tests: `test/account_status_test.dart`.
- **H1 — Admin decisions.**
  - Verification, provider-status, account-status, report-outcome and dispute notifications open
    the matching screen.
  - Account and verification changes refresh the signed-in user straight away.
- **H2 — Policies.** Terms, Privacy and the new Community Guidelines screen render the admin's text
  from `GET /platform`, falling back to the bundled text. Registration links all three.
  Tests: `test/platform_test.dart`.
- **H4 — Release readiness.**
  - `com.skillserve.mobile` and the "SkillServe" label.
  - Launcher icon and branded splash (light and dark), plus `ic_stat_notification` for system
    notifications.
  - `key.properties` release signing (debug key plus a warning when absent).
  - `pubspec.lock` is tracked, `*.log` is ignored, and the committed log was removed. Version
    stays `1.0.0+1` for the first release.
  - The release APK builds.

**Medium and Low from the full audit:**
- **M2 — Account deactivation decision.** Documented in `TEST_PLAN.md` ("Design decisions to defend")
  and `README.md`: accounts are active or deleted; deletion is a restorable soft delete.
- **M6 — Test evidence.** `TEST_PLAN.md` maps every mobile requirement (M 1.1 … M 17.1) to its screen,
  endpoint, Flutter/backend tests and UAT steps, with space for results.
- **M3 (app side).** A 429 from the new sign-up/OTP/password-reset rate limits shows "Too many
  attempts. Please wait a minute and try again." (`lib/core/utils/api_error.dart`,
  `test/api_error_test.dart`).
- **M4 (app side).** Review moderation notices from the backend carry the booking id, so tapping one
  opens the booking.
- **L4** `README.md` rewritten: real structure (`lib/features/*`), no mock mode, secure token storage,
  realtime, closed-app notifications, build steps.
- **L6** `workmanager` is already the latest release; the Kotlin Gradle Plugin warning is upstream and
  harmless. Nothing further to do until a new release ships.

**Earlier on 2026-09-21:**

- **Notifications while the app is closed — without Firebase.** Android WorkManager runs a
  background check about every 15 minutes (the OS minimum; it may stretch it to save battery)
  and posts each new notification as a system notification; tapping one opens what it is about
  (`lib/core/services/background_notifications.dart`). The check uses a separate read-only token
  (`POST /api/client/v1/notifications/background-token`, then
  `GET /api/client/v1/notifications/background`) that can do nothing else and never refreshes, so it
  cannot disturb the signed-in session. While the app is open, Reverb stays the instant path and
  the check shows nothing twice. Not instant when closed, and a force-stopped app gets nothing
  until reopened — that needs FCM, which the project does not use.
- **Help Center search works.** It filters the FAQs by question and answer as you type, with a
  no-results message; the FAQs now also cover rescheduling, payments and favorites.
- **Presence and typing in chat.** Each booking conversation joins a Reverb presence channel
  (`presence-booking-chat.{booking}`, participants only). The header shows "In this chat" when the
  other person has the conversation open and "typing…" while they type (client events, renewed
  every few seconds and expiring after five).
- **Active Jobs button.** A confirmed job now offers "Start job"; only a job in progress offers
  "Mark as completed".

- **Favorites persist.** They are saved on the server (`lib/features/marketplace/services/favorites_service.dart`),
  loaded when a customer signs in and cleared on sign-out. Hearts flip at once and flip back if the
  save fails; guests are asked to sign in. The Favorites screen reads the saved list, with loading,
  error and pull-to-refresh.
- **Payments can be settled.** A provider taps "Payment received" on a completed, unpaid job in
  Booking Details (optional reference number); the customer is notified. Payment details and
  Earnings show paid dates, refunds and the real status (Paid / Unpaid / Refunded / Partly refunded).
- **Tokens are in secure storage.** `lib/core/services/token_storage.dart` uses
  `flutter_secure_storage` (Keychain / Android Keystore). Tokens an older build left in
  SharedPreferences are moved on first launch, so nobody is signed out by the update.

- **Booking lifecycle gaps.** A provider can cancel a job they already accepted, before it starts,
  from Booking Details ("Cancel job"; a reason is required and reaches the customer). A customer can
  reschedule a pending or confirmed booking from Booking Details: the new Reschedule screen offers
  only slots inside the provider's hours that fit the booking's length. A confirmed booking goes
  back to pending for the provider to accept again, and the provider sees a "Rescheduled" label and
  banner. The slot rules are shared with the booking form (`views/schedule_picker.dart`).

- **Stay signed in.** Closing and reopening the app no longer signs the user out:
  - the signed-in account is cached and restored at launch, even offline or while the backend is
    cold-starting (the splash screen now waits for this instead of a fixed 2 seconds);
  - an expired one-hour access token is renewed from the refresh token automatically
    (`lib/core/services/api_client.dart`), one refresh at a time because the backend revokes the
    whole session if a refresh token is reused;
  - the old forced eight-hour logout is removed;
  - only a real refusal from the server (sign-out elsewhere, suspension, deleted account) returns
    the user to login.
- **Separate customer and provider apps.** The router now enforces roles
  (`redirectFor` in `lib/routes/app_router.dart`): a provider cannot open customer screens or shop
  the marketplace, a customer cannot open provider screens, and shared screens (notifications,
  messages, booking details, reports, support, account) stay open to both. Signed-in users skip
  the sign-in screens. This also fixed guests being sent to login from the public
  `/provider-preview` page, and several provider screens that were reachable signed out.
- Provider "View public profile" pointed at a route that did not exist; it now opens the read-only
  preview, which shows a provider "this is how customers see your profile" instead of a booking
  button.
- **Payments** rebuilt from each booking's real payment record, replacing endpoints that never
  existed and made-up transaction references.
- **Earnings** now shows real figures: job prices, the platform fee, and what the provider keeps.
  The fake payout-method picker and the Withdrawal History screen (which showed hardcoded payouts
  such as "WD-1042 ₱8,500") are removed. The dashboard "This Month" card was summing all-time
  earnings; it now shows this month only.
- Support tickets are available to providers too.
- Reviews and messages can be reported; dispute photos can be attached from My Reports.
- My Reviews no longer flags every review, because the published status is `active`, not
  `published`.
- Idle sessions last a year instead of 14 days (backend default), so a user who keeps opening the
  app stays signed in until they sign out.
- Chat: an incoming message now updates the inbox row from the push itself, and an open thread makes
  one small "mark read" request instead of re-reading the thread and the whole inbox. Only a message
  in a conversation the inbox has not loaded yet triggers a reload.
- Running Flutter from WSL: use `tool/wsl-flutter.sh` (e.g. `tool/wsl-flutter.sh test`), documented
  in the README. The Windows SDK itself is unchanged.
