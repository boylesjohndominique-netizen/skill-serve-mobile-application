# SkillServe Test Plan — Mobile App

User acceptance test (UAT) plan and requirements traceability matrix for the Flutter app
(`SkillServe_User_Mobile_Functionalities_Flutter.pdf`). The admin web has its own plan in
`web-project-bsit3blk3group6/TEST_PLAN.md`. Open defects are in `PENDING_FIXES.md`; a row that
depends on one says so (for example "Open: C1").

## How to use this document

1. Run the automated checks and record the totals and date.
2. Install the **release build** on a real Android phone pointed at the deployed backend, then walk
   through every row. Use two phones (or a phone and an emulator) for the rows that involve both a
   customer and a provider. Demo logins on a demo database: `customer@skillserve.test` and
   `provider@skillserve.test`, password `SkillServe#2026`.
3. Fill in **Result** (Pass / Fail + date, and the defect ID if it fails). A requirement is done when
   its automated tests pass and its UAT row passes.

## Automated checks

| Suite | Command | Covers |
|-------|---------|--------|
| Static analysis | `tool/wsl-flutter.sh analyze` | Lints, types |
| Flutter tests | `tool/wsl-flutter.sh test` | Models, controllers, route guards, token storage, realtime presence, background checks, layout overflow sweeps |
| Backend API tests | `docker compose exec backend composer test` (web repo) | Every `/api/client/v1/*` endpoint the app calls |
| Release build | `flutter build apk --release --dart-define-from-file=env/production.json` | The app compiles and signs for release as `com.skillserve.mobile` |

| Run date | analyze | flutter test | backend tests | release APK |
|----------|---------|--------------|---------------|-------------|
| | | | | |

## Design decisions to defend

- **No account deactivation (M 15.2).** Accounts are active or deleted. "Delete account" is a soft
  delete: the account is gone from the platform immediately, an administrator can restore it, and
  it is purged after 30 days only if nothing references it. That covers what a deactivation would
  do, so there is one clear path instead of two overlapping ones. Deletion is refused while the
  user still has open bookings, so nobody is left mid-job.
- **Payments are recorded, not processed.** Customers pay providers directly (cash, GCash…); the
  provider confirms "Payment received" and the app shows the status and any refund.
- **No Firebase.** Realtime runs on the project's own Laravel Reverb server. Closed-app
  notifications use Android WorkManager polling with a read-only token (about every 15 minutes; a
  force-stopped app gets nothing until reopened).
- **Separate customer and provider experiences** inside one app, enforced by route guards
  (`redirectFor` in `lib/routes/app_router.dart`) and by the API.
- **Tokens in secure storage** (Android Keystore); sessions last until sign-out.

## Traceability matrix — Mobile

Columns: **Screen** (route) · **API** (`/api/client/v1` omitted) · **Tests** (Flutter test files /
backend test classes) · **UAT** steps → expected result.

### 1. User Authentication and Account

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 1.1 | Registration | `/register`, `/google-register`, `/verify-email` | `POST /auth/register`, `/auth/register-provider`, `/auth/verify-otp`, `/auth/resend-otp` | auth_form_locking_test, google_registration_screen_test · ClientEmailOtpTest, ClientProviderRegistrationTest, CancelRegistrationTest | Register as customer and as provider → OTP email → account active | |
| M 1.2 | Login | `/login` | `POST /auth/login`, `/auth/google` | session_roles_payments_test · ClientAuthenticationTest, ClientGoogleAuthTest | Customer lands on the customer home, provider on the provider dashboard | |
| M 1.3 | Logout | Settings → Sign out | `POST /auth/logout` | session_roles_payments_test · ClientAuthenticationTest | Returns to login; reopening the app stays signed out | |
| M 1.4 | Password management | `/change-password`, `/forgot-password` | `POST /auth/change-password`, `/auth/forgot-password`, `/auth/reset-password` | user_account_profile_test · ClientAuthenticationTest | Change password → other devices signed out; reset link email works | |
| M 1.5 | Session management | — | `POST /auth/refresh` | session_roles_payments_test · ClientAuthenticationTest | Close and reopen after an hour → still signed in; revoke from another device → returned to login | |
| M 1.6 | Account status display | — | login/refresh refusal | account_status_test · AccountStatusTest | A suspended or banned account is signed out and the login screen shows the reason and the end date | |

### 2. User Profile

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 2.1 | View profile | Profile tab | `GET /auth/me` | user_account_profile_test · ClientProfileTest | Name, email, phone, photo, verification shown | |
| M 2.2 | Edit profile | `/edit-profile` | `PATCH /auth/me` | user_account_profile_test · ClientProfileTest | Edit phone → saved after restart | |
| M 2.3 | Profile photo | `/edit-profile` | `POST/DELETE /auth/me/photo` | user_account_profile_test · ClientProfileTest | Add, change, remove photo | |
| M 2.4 | Account status | Profile | `GET /auth/me` | account_status_test | Settings shows the account status card | |
| M 2.5 | Activity history | `/activity-history` | bookings, reviews, reports | security_preferences_test | Recent bookings, reviews and reports listed | |

### 3. Service Discovery

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 3.1 | Browse services | `/browse`, home | `GET /services` | discovery_test · ClientMarketplaceTest | Only approved, visible services from verified providers | |
| M 3.2 | Search services | `/search` | `GET /services?search=` | discovery_test · ClientMarketplaceTest | Search by title, provider, category | |
| M 3.3 | Filter services | filter sheet | `GET /services?category_id=&min_rating=&provider_id=&available=` | discovery_test · ClientMarketplaceTest | Category, rating, provider, availability filters | |
| M 3.4 | Service details | `/service-details/:id` | `GET /services/{id}` | marketplace_models_test · ClientMarketplaceTest | Description, price (₱), provider, ratings, Book button | |
| M 3.5 | Featured services | home | `GET /services?featured=1` | discovery_test · ClientMarketplaceTest | Service featured in admin appears | |
| M 3.6 | Categories | `/categories` | `GET /categories`, `/categories/{id}` | marketplace_models_test · ClientMarketplaceTest | Only enabled categories and subcategories | |

### 4. Service Provider Discovery

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 4.1 | Browse providers | home, `/search` | `GET /providers` | discovery_test · ClientMarketplaceTest | Verified, active, public providers only | |
| M 4.2 | Search providers | `/search` | `GET /providers?search=` | discovery_test · ClientMarketplaceTest | Search by name, skill, location | |
| M 4.3 | Filter providers | filter sheet | `GET /providers?category_id=&min_rating=&featured=&available=&available_day=` | discovery_test · ClientMarketplaceTest | Category, rating, recognition, availability | |
| M 4.4 | Provider profile | `/provider-profile/:id` | `GET /providers/{id}` | marketplace_models_test · ClientMarketplaceTest | Skills, experience, portfolio, services, ratings, badges, hours | |
| M 4.5 | Verification status | provider profile | same | marketplace_models_test | Verified seal shown | |
| M 4.6 | Provider recognition | provider profile, home | same | marketplace_models_test · ProviderRecognitionTest | Badges, featured, top-rated shown | |

### 5. Booking

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 5.1 | Create booking | `/booking-form/:providerId` | `POST /bookings` | booking_test · ClientMarketplaceTest | Only slots inside the provider's hours (Manila time); double booking refused; the saved time matches the time picked | |
| M 5.2 | Booking details | `/booking-details/:id` | `GET /bookings/{id}` | booking_test | Service, provider, schedule, status, payment | |
| M 5.3 | My bookings | `/booking-history` | `GET /bookings` | booking_test | Current and past bookings by status | |
| M 5.4 | Monitor status | booking details | realtime + `GET /bookings/{id}` | booking_test · ProviderBookingTest | Provider accepts on phone 2 → phone 1 updates live | |
| M 5.5 | Booking history | booking details → timeline | `GET /bookings/{id}` | booking_test · BookingRescheduleTest | Requested, rescheduled, accepted, started, completed, paid in order | |
| M 5.6 | Cancel booking | booking details | `PATCH /bookings/{id}/cancel`; provider `…/provider/bookings/{id}/cancel`, reschedule `PATCH /bookings/{id}/reschedule` | booking_test · ProviderBookingTest, BookingRescheduleTest, SettingsEnforcementTest | Cancel with reason → provider notified; inside the cancellation window the dialog warns of the fee and the booking records it | |
| M 5.7 | Report or dispute | booking details | `PATCH /bookings/{id}/dispute` | reports_support_test · BookingDisputeTest | Dispute an active/completed job | |
| (extra) | Choose how to pay | `/booking-form/:providerId` step 3 | `POST /bookings` (`payment_method`) | booking_test · ClientMarketplaceTest | Exactly two methods are offered, On-hand and GCash; nothing is charged | |
| (extra) | Where to send a GCash payment | booking details → "How to pay" | `GET /bookings/{id}` (`payment_instructions`) | booking_test · DirectPaymentTest | On an unpaid GCash booking: the provider's GCash number and account name, the amount and the booking number, with a copy button. A provider who saved none → a note to message them instead. Nothing shown once paid or cancelled | |

### 6. Reviews and Ratings

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 6.1 | Submit review | `/write-review/:bookingId` | `POST /reviews` | notifications_reviews_test · ClientMarketplaceTest | Only for a completed, own, unreviewed booking | |
| M 6.2 | Submit rating | same | same | notifications_reviews_test | 1–5 stars required | |
| M 6.3 | View reviews | `/reviews/:providerId` | `GET /providers/{id}` | notifications_reviews_test | Published reviews only | |
| M 6.4 | Report review | review card → Report | `POST /reports` (review_id) | reports_support_test · ClientReportTest | Report → appears in admin Reported | |
| M 6.5 | My reviews | `/my-reviews` | `GET /reviews` | notifications_reviews_test | Own reviews; edit allowed | |

### 7. Messaging and Communication

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 7.1 | Conversations | Messages tab | `GET /conversations` | messaging_test · ConversationTest | One thread per booking, unread counts | |
| M 7.2 | Send message | `/chat-conversation/:bookingId` | `POST /bookings/{id}/messages` | messaging_test · ClientCommunicationTest | Sent message appears once; retry on failure | |
| M 7.3 | Receive messages | same | Reverb private channel | chat_realtime_test, presence_background_test | Message from phone 2 appears instantly; "typing…" and "In this chat" show | |
| M 7.4 | Message history | same | `GET /bookings/{id}/messages` | messaging_test | Full history after reopening | |
| M 7.5 | Report message | long-press → Report | `POST /reports` (message_id) | reports_support_test · ClientReportTest | Report → admin Reports | |

### 8. Notifications and Announcements

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 8.1 | View notifications | `/notifications` | `GET /notifications` | notifications_reviews_test · ClientCommunicationTest | Feed with read/unread | |
| M 8.2 | Booking notifications | banner / system notification | Reverb, `GET /notifications/background` | presence_background_test · ProviderBookingTest, BackgroundNotificationTest | Created, confirmed, rescheduled, cancelled, completed, paid, disputed each notify the other party; also with the app closed | |
| M 8.3 | Service notifications | same | same | ServiceManagementTest | Service approved/rejected in admin → provider notified | |
| M 8.4 | Announcements | `/notifications` | same | NotificationsTest | Admin announcement arrives | |
| M 8.5 | Targeted notifications | same | same | NotificationsTest | Provider-only announcement does not reach a customer | |
| M 8.6 | Notification history | `/notifications` | `GET /notifications` | notifications_reviews_test | Older notifications scroll in | |

### 9. Service Provider Account

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 9.1 | Become a provider | `/register` (provider), `/provider-onboarding` | `POST /auth/register-provider` | provider_account_test · ClientProviderRegistrationTest | Provider account created | |
| M 9.2 | Manage provider profile | provider Settings, `/portfolio`, `/availability` | `GET/PATCH /provider/profile`, portfolio, availability | provider_account_test · ProviderAccountTest | Skills, experience, portfolio, hours saved | |
| M 9.3 | Submit verification | `/verification-status` | `POST /provider/verification` | verification_test · ProviderVerificationTest | Upload an ID photo or PDF → status pending; it appears in the admin review | |
| M 9.4 | Verification status | `/verification-status` | `GET /provider/verification` | verification_test · provider_account_test | Status, the reviewer's message and the documents sent are shown; a decision arrives as a notification | |
| M 9.5 | Respond to info request | `/verification-status` | `POST /provider/verification` | verification_test · ProviderVerificationTest | After "request info", upload the requested document → back to pending | |
| M 9.6 | Provider restrictions | Settings, login | `GET /auth/me` | account_status_test · AccountStatusTest | A provider suspension is shown with its reason | |
| (extra) | Outstanding commission | `/commissions` | `GET /provider/commissions` | identity_test · CommissionLedgerTest | Each unremitted booking with its commission and rate, the total, and that new work is paused. Nothing to pay in the app | |
| (extra) | GCash details | `/gcash-details` | `PATCH /provider/profile` | DirectPaymentTest | Saving 09XX XXX XXXX (or +63…) stores 11 digits; the customer's booking then shows them | |

### 10. Service Management for Providers

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 10.1 | Create service | `/add-service` | `POST /provider/services` | provider_services_test · ProviderServiceTest | Verified provider only; lands as pending | |
| M 10.2 | My services | `/my-services` | `GET /provider/services` | provider_services_test · ProviderServiceTest | Services with approval status | |
| M 10.3 | Edit service | `/edit-service/:id` | `PUT/PATCH /provider/services/{id}` | provider_services_test · ProviderServiceTest | Edit → returns to pending review | |
| M 10.4 | Submit for review | same | same | ProviderServiceTest | Rejected service resubmitted | |
| M 10.5 | Approval status | `/my-services` | same | provider_services_test | Pending / approved / rejected / hidden badges | |
| M 10.6 | Availability | `/availability` | `GET/PUT /provider/availability` | provider_account_test · ProviderAccountTest | Weekly hours restrict bookable slots; "not accepting bookings" hides the provider from Available | |

### 11. Dispute

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 11.1 | Submit dispute | booking details → Raise a dispute | `PATCH /bookings/{id}/dispute` | reports_support_test · BookingDisputeTest | Customer or provider can dispute once | |
| M 11.2 | My disputes | `/my-reports` | `GET /disputes` | reports_support_test · BookingDisputeTest | Own disputes with status | |
| M 11.3 | Dispute details | dispute card | same | reports_support_test | Statement, evidence, status | |
| M 11.4 | Submit evidence | dispute card → Add photo | `POST /bookings/{id}/dispute/evidence` | reports_support_test · BookingDisputeTest | Up to 5 photos; admin can open them | |
| M 11.5 | Dispute updates | dispute card, notifications | same | BookingDisputeTest · AdminDecisionNotificationTest | Status changes shown; both parties are notified | |

### 12. Support

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 12.1 | Create ticket | `/support/new` | `POST /support/tickets` | reports_support_test · ClientCommunicationTest, ProviderSupportTicketTest | Customer and provider can open tickets | |
| M 12.2 | My tickets | `/support/tickets` | `GET /support/tickets` | reports_support_test | Own tickets with status | |
| M 12.3 | Ticket details | `/support/tickets/:id` | `GET /support/tickets/{id}` | reports_support_test | Concern, replies, history | |
| M 12.4 | Reply | same | `POST /support/tickets/{id}/replies` | reports_support_test · ClientCommunicationTest | Reply → admin sees it | |
| M 12.5 | Ticket status | same | same | reports_support_test | Open, assigned, in progress, resolved | |

### 13. Search and Personalized Discovery

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 13.1 | Global search | `/search` | `GET /services`, `/providers` | discovery_test | Services and providers in one search | |
| M 13.2 | Suggestions | `/search` | catalog | discovery_test | Suggestions while typing | |
| M 13.3 | Recent searches | `/search` | device-local | discovery_test | Recent terms listed and clearable; cleared on sign-out | |
| M 13.4 | Featured providers | home | `GET /providers?featured=1` | discovery_test · ClientMarketplaceTest | Admin-featured providers | |
| M 13.5 | Top-rated providers | home | `GET /providers?sort=average_rating` | discovery_test | Highest rated first | |
| — | Favorites | heart, `/favorites` | `GET/PUT/DELETE /favorites` | favorites_test · FavoriteProviderTest | Saved providers survive reinstall and sign-in on another phone | |

### 13b. Identity Verification (both roles)

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| (extra) | Submit the National ID | `/identity-verification` | `POST /identity-verification` | identity_test · IdentityVerificationTest | 16-digit number, name, birthdate and both sides of the card → status pending; it appears in the admin review queue | |
| (extra) | See where it stands | `/identity-verification` | `GET /identity-verification` | identity_test | Under review, or approved, with the card's last four digits; a rejection shows the reviewer's reason and allows resubmission | |
| (extra) | Asked for at registration (email) | OTP → `/identity-verification` | — | — | A new customer lands on the ID screen; a provider continues to `/provider-onboarding` after it | |
| (extra) | Asked for at registration (Google) | `/google-register` → `/identity-verification` | — | google_registration_screen_test | Same landing as the email path. Google verifies the address, so there is no OTP screen — the ID prompt must not be skippable by signing up with Google | |
| (extra) | Know why an account is blocked | customer home, provider dashboard | `GET /transaction-eligibility` | identity_test · IdentityEnforcementTest | With the requirement on: an unverified account sees a banner that opens the ID screen; a provider owing commission sees one that opens `/commissions`; a verified account sees nothing | |
| (extra) | Skipping while not required | `/identity-verification` | `GET /transaction-eligibility` | identity_test | With the requirement off (or the account grandfathered), "I'll do this later" is offered; with it on, it is not | |

### 14. User Settings and Preferences

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 14.1 | Notification preferences | `/notification-preferences` | `GET/PUT /preferences` | preferences_controller_test · ClientPreferencesTest | Muting bookings stops booking notifications | |
| M 14.2 | Privacy settings | `/privacy-settings` | same | security_preferences_test · ClientPreferencesTest | Private profile hides a provider from discovery | |
| M 14.3 | Application preferences | `/application-preferences` | same | preferences_controller_test | Theme and reduce-motion apply at once | |
| M 14.4 | Platform policies | `/terms`, `/privacy`, `/community-guidelines`, `/help-center` | `GET /platform` | platform_test | The admin's policy texts are shown, with the bundled text when offline | |

### 15. Data and Account Control

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 15.1 | View account data | `/account-data` | `GET /auth/me/data-export` | security_preferences_test · AccountDataTest | Profile, bookings, reviews, reports, tickets, favorites; no password | |
| M 15.2 | Request deactivation | — | — | — | Design decision: covered by restorable deletion (see above) | |
| M 15.3 | Request deletion | `/account-deletion` | `DELETE /auth/me` | security_preferences_test · AccountDataTest | Refused with open bookings; otherwise signed out and gone | |
| M 15.4 | Restriction information | login, Settings | `meta.account` | account_status_test | The reason and end date of a restriction are shown | |

### 16. Mobile Security

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 16.1 | Secure authentication | — | Sanctum + refresh tokens | session_roles_payments_test (secure storage) · ClientAuthenticationTest, ClientAuthRateLimitTest | Tokens in secure storage; brute force rate-limited | |
| M 16.2 | Session expiration | — | `POST /auth/refresh` | session_roles_payments_test | Password changed elsewhere → returned to login | |
| M 16.3 | Unauthorized access | route guards | policies | session_roles_payments_test · BackgroundNotificationTest | Customer cannot open provider screens and vice versa; other users' bookings return 403 | |
| M 16.4 | Security notifications | `/security-activity` | session state | security_preferences_test | Shows the current session and whether the server ended the last one (password changed, suspended); restriction details come from `meta.account` | |

### 17. Logout

| ID | Requirement | Screen | API | Tests | UAT → expected | Result |
|----|-------------|--------|-----|-------|----------------|--------|
| M 17.1 | User logout | Settings → Sign out | `POST /auth/logout` | session_roles_payments_test · ClientAuthenticationTest | Back to the sign-in screen; closed-app notifications stop | |
