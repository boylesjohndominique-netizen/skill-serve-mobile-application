# Pending Fixes — SkillServe Mobile (Flutter)

Last audited: 2026-09-21. Each item names where the problem is, why it matters,
and a suggested fix. Ordered by priority. The web project has its own list in
`web-project-bsit3blk3group6/PENDING_FIXES.md`; items that need backend work
first are marked **(needs backend)**.

---

## High

Nothing open.

---

## Medium

### 4. No notifications while the app is closed
- **Why:** closed-app delivery needs FCM (Android) / APNs (iOS). The project deliberately uses
  realtime over the Laravel backend (Reverb) instead of Firebase, so notifications arrive
  instantly while the app is open and wait in the feed otherwise.
- **Fix, if wanted later:** FCM/APNs is the only transport the OS offers for a closed app; it can
  be sent from Laravel without using Firebase for anything else.

### 5. Help Center search does nothing
- **Where:** `lib/features/settings/views/help_center_screen.dart` — `AppSearchBar` has no
  `onChanged`.
- **Fix:** filter `_faqs` by question and answer text, as `chat_list_screen.dart` filters
  conversations.

### 7. No presence or typing indicators in chat
- Deliberately not faked. Needs a presence channel on Reverb if wanted.

---

## Low

### 8. Active Jobs offers "Mark as completed" on jobs that have not started
- **Where:** `lib/features/provider/views/active_jobs_screen.dart` lists `controller.active`
  (confirmed and in progress) and gives every card "Mark as completed".
- **Why it matters:** on a confirmed job the API refuses it ("Only a job in progress can be
  completed"), so the button always fails there.
- **Fix:** show "Start job" for a confirmed booking and "Mark as completed" only for one in
  progress, as the Booking Requests tabs already do.

---

## Resolved on 2026-09-21

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
