# Client Authentication

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `POST /api/client/v1/auth/cancel-registration`

Removes the parked registration (and, for accounts created before sign-ups were deferred, the unverified account itself) so the email can be used again straight away. Send the `registration_token` from the sign-up response; older app versions send the password chosen at registration instead.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `email` | yes | string, format=email |
| `registration_token` | no | string |
| `password` | no | string, format=password |

### Responses

#### HTTP 200: Sign-up cancelled (always returned, even for unknown accounts, to prevent enumeration)

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation error

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/change-password`

Change the current customer's password

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `current_password` | yes | string, format=password |
| `password` | yes | string, format=password, minLength=8 |
| `password_confirmation` | yes | string, format=password |

### Responses

#### HTTP 200: Password changed and sessions revoked

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated or expired token

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Token is not a client token or account is inactive

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation error or wrong current password

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/complete-registration`

For a sign-up whose code was confirmed with POST /auth/verify-otp. `registration_token` is the one returned when the sign-up was started (POST /auth/register, /auth/register-provider or /auth/google/register), so knowing the email is not enough. Creates the customer or provider account and signs it in.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `email` | yes | string, format=email |
| `registration_token` | yes | string |
| `password` | yes | string, format=password, minLength=8 |
| `password_confirmation` | yes | string, format=password |

### Responses

#### HTTP 201: Account created and signed in

Response schema: `#/components/schemas/ClientAuthEnvelope`

#### HTTP 409: The email was registered by someone else in the meantime, or this sign-up was already completed

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation error; the sign-up expired or the token does not match; or the code has not been confirmed yet

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/forgot-password`

Step 1 of 3: this code, then POST /auth/verify-reset-code, then POST /auth/reset-password with the new password. Works for every mobile account, including one created with Google sign-in. An address with no mobile account answers 404, so the app moves to the code screen only for a real account; a suspended or banned account answers 403 with `meta.account`, as at login. An address sent a code in the last 60 seconds answers 202 without a new email: the code already sent is the one to enter.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `email` | yes | string, format=email |

### Responses

#### HTTP 202: A code was emailed to the account (or one sent in the last 60 seconds is still valid)

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: The account is suspended or banned (`meta.account`)

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 404: No mobile account uses this email (`errors.email`)

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation error

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 503: The code could not be sent

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/google`

Resolves the Google identity against existing accounts. Google alone never signs in: the account password is required too.
 * linked Google account, or an account owning the Google-verified email, without `password` -> `password_required: true` and the account `email`; nothing else happens. Call again with the same `id_token` and the `password`.
 * the same, with the right `password` -> signed in; the account is linked and its email marked verified. Accounts created by Google sign-up before passwords were required set one with Forgot password.
 * no account -> nothing is created. Responds with `registration_required: true` plus a name/email draft for the sign-up form, which is submitted to POST /auth/google/register.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `id_token` | yes | string |
| `password` | no | string, format=password |

### Responses

#### HTTP 200: Signed in, the password is required, or a sign-up is required

Response schema: `#/components/schemas/ClientGoogleAuthEnvelope`

#### HTTP 401: Invalid Google token, or incorrect password

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Account not active, or the email belongs to an administrator

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation error

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/google/register`

For a Google identity with no account. The ID token is re-verified, so the email always comes from Google. Like an email sign-up nothing is created yet: a 6-digit code is emailed to the Google address, then POST /auth/verify-otp and POST /auth/complete-registration (with the `registration_token` from this response) create the account, linked to the Google identity.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `id_token` | yes | string |
| `first_name` | yes | string, maxLength=255 |
| `last_name` | yes | string, maxLength=255 |
| `role` | yes | string, one of: `customer`, `provider` |
| `business_name` | no | string, maxLength=255 |
| `specialization` | no | string, maxLength=255 |
| `experience_years` | no | integer, minimum=0 |
| `bio` | no | string, maxLength=5000 |
| `birthday` | yes | string, format=date |
| `address_details` | no | object |

### Responses

#### HTTP 202: Verification code sent to the Google address

Response schema: `#/components/schemas/ClientPendingRegistrationEnvelope`

#### HTTP 401: Invalid or expired Google token

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: The email belongs to an administrator, or provider sign-ups are closed

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 409: This Google identity already has an account; log in instead

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation error

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 429: A code was sent moments ago; wait before retrying

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 503: The verification email could not be sent

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/login`

Login as a customer

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `email` | yes | string, format=email |
| `password` | yes | string, format=password |

### Responses

#### HTTP 200: Logged in successfully

Response schema: `#/components/schemas/ClientAuthEnvelope`

#### HTTP 401: Invalid credentials

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Inactive account, or a sign-up that has not been verified yet (`meta.verification_required`)

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation error

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/logout`

Logout and revoke customer sessions

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Logged out successfully

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated or expired token

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Token is not a client token or account is inactive

Response schema: `#/components/schemas/ApiEnvelope`

## `DELETE /api/client/v1/auth/me`

Confirmed with the account password. Refused while the account still has open bookings, so the other party is never left mid-job. The account is soft-deleted and every device is signed out; an administrator can restore it from Data Management. There is no separate "pending deletion" state.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `password` | yes | string |
| `reason` | no | string, maxLength=1000 |

### Responses

#### HTTP 200: Account deleted and sessions revoked

Response schema: `see openapi.json`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active mobile account required

Response schema: `see openapi.json`

#### HTTP 422: Wrong password, or open bookings remain

Response schema: `see openapi.json`

## `GET /api/client/v1/auth/me`

Get the current customer

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Authenticated customer

Response schema: `#/components/schemas/ClientUserEnvelope`

#### HTTP 401: Unauthenticated or expired token

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Token is not a client token or account is inactive

Response schema: `#/components/schemas/ApiEnvelope`

## `PATCH /api/client/v1/auth/me`

Partial update: only the fields present in the body are changed. Email and role are not editable here — changing an address re-opens verification, and the role governs authorization.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `first_name` | no | string, maxLength=255 |
| `last_name` | no | string, maxLength=255 |
| `phone` | no | string |
| `address` | no | string, maxLength=500 |
| `address_details` | no | object |

### Responses

#### HTTP 200: Updated profile

Response schema: `#/components/schemas/ClientUserEnvelope`

#### HTTP 401: Unauthenticated or expired token

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Token is not a client token or account is inactive

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation error

Response schema: `#/components/schemas/ApiEnvelope`

## `GET /api/client/v1/auth/me/data-export`

Own data only: profile, preferences, provider profile, bookings, reviews, reports filed and support tickets.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: The account's data

Response schema: `#/components/schemas/AccountDataExportEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active mobile account required

Response schema: `see openapi.json`

## `DELETE /api/client/v1/auth/me/photo`

Deletes the stored file and clears the reference. Succeeds even when no photo is set, so the call is safe to repeat.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Photo removed

Response schema: `#/components/schemas/ClientUserEnvelope`

#### HTTP 401: Unauthenticated or expired token

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Token is not a client token or account is inactive

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/me/photo`

Multipart upload. The previous photo is deleted once the new one is stored. The response carries the new absolute URL in `profile_picture`.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Photo stored

Response schema: `#/components/schemas/ClientUserEnvelope`

#### HTTP 401: Unauthenticated or expired token

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Token is not a client token or account is inactive

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Missing, oversized, or non-image file

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/refresh`

Rotate a customer refresh token

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `refresh_token` | yes | string, minLength=32 |

### Responses

#### HTTP 200: Tokens rotated

Response schema: `#/components/schemas/ClientAuthEnvelope`

#### HTTP 401: Invalid, expired, or reused refresh token

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Inactive or unverified customer account

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation error

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/register`

Parks the sign-up and emails a 6-digit code. Next: POST /auth/verify-otp with the code, then POST /auth/complete-registration with the password and the `registration_token` from this response, which creates the account. Abandoning any step leaves the address free to register again.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `first_name` | yes | string, maxLength=255 |
| `last_name` | yes | string, maxLength=255 |
| `email` | yes | string, format=email |
| `password` | no | string, format=password, minLength=8 |
| `password_confirmation` | no | string, format=password |
| `birthday` | yes | string, format=date |
| `address_details` | no | object |

### Responses

#### HTTP 202: Verification code sent; confirm it to create the account

Response schema: `#/components/schemas/ClientPendingRegistrationEnvelope`

#### HTTP 422: Validation error

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 429: A code was sent moments ago; wait before retrying

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 503: The verification email could not be sent

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/register-provider`

Same deferred flow as customer registration: code (POST /auth/verify-otp), then password (POST /auth/complete-registration), which creates the provider account and its pending `provider_profiles` row.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `first_name` | yes | string, maxLength=255 |
| `last_name` | yes | string, maxLength=255 |
| `email` | yes | string, format=email |
| `password` | no | string, format=password, minLength=8 |
| `password_confirmation` | no | string, format=password |
| `business_name` | no | string, maxLength=255 |
| `specialization` | yes | string, maxLength=255 |
| `experience_years` | no | integer, minimum=0 |
| `bio` | no | string, maxLength=5000 |
| `birthday` | yes | string, format=date |
| `address_details` | no | object |

### Responses

#### HTTP 202: Verification code sent; confirm it to create the provider account

Response schema: `#/components/schemas/ClientPendingRegistrationEnvelope`

#### HTTP 422: Validation error

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 429: A code was sent moments ago; wait before retrying

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 503: The verification email could not be sent

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/resend-otp`

Resend the sign-up verification OTP

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `email` | yes | string, format=email |

### Responses

#### HTTP 200: The email is already verified

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 202: A new code has been sent

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 404: No sign-up or account found

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 429: Resend cooldown active

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 503: The verification email could not be sent; it can be retried at once

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/reset-password`

Step 3 of 3. `token` is the `reset_token` from POST /auth/verify-reset-code. Signs the account out everywhere.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `token` | yes | string |
| `email` | yes | string, format=email |
| `password` | yes | string, format=password, minLength=8 |
| `password_confirmation` | yes | string, format=password |

### Responses

#### HTTP 200: Password reset and sessions revoked

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Invalid or expired reset token

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/verification-notification`

Resend the customer email verification link

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 202: Verification email sent

Response schema: `#/components/schemas/ClientUserEnvelope`

#### HTTP 200: Email is already verified

Response schema: `#/components/schemas/ClientUserEnvelope`

#### HTTP 401: Unauthenticated or expired token

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Inactive or non-client account

Response schema: `#/components/schemas/ApiEnvelope`

## `GET /api/client/v1/auth/verify-email/{user}/{hash}`

Verify a customer email address from its signed link

**Authentication:** Public

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `user` | path | yes | integer |
| `hash` | path | yes | string |
| `expires` | query | yes | integer |
| `signature` | query | yes | string |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Email verified

Response schema: `#/components/schemas/ClientUserEnvelope`

#### HTTP 403: Invalid or expired verification link

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 404: Customer not found

Response schema: `see openapi.json`

## `POST /api/client/v1/auth/verify-otp`

* A sign-up started without a password (current apps, email or Google): the address is marked verified and the response is the pending registration with `password_required: true`. No account yet: choose the password with POST /auth/complete-registration. Repeating the call after success returns the same.
* A sign-up parked by an older app version with its password: the account is created and a session returned.
* An account registered before sign-ups were deferred: marked verified and signed in.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `email` | yes | string, format=email |
| `code` | yes | string, minLength=6, maxLength=6 |

### Responses

#### HTTP 200: Email verified: either the pending registration (`password_required: true`) or, for older sign-ups, a session

Response schema: `see openapi.json`

#### HTTP 403: Account is not active

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 404: No sign-up or account found for this email

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 409: The email was registered by someone else while this code was outstanding

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Invalid or expired code

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 429: Too many incorrect attempts

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/verify-reset-code`

Step 2 of 3. Returns a single-use `reset_token` (valid 60 minutes) for POST /auth/reset-password. Five wrong codes void the code; request a new one.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `email` | yes | string, format=email |
| `code` | yes | string, minLength=6, maxLength=6 |

### Responses

#### HTTP 200: Code confirmed

Response schema: `see openapi.json`

#### HTTP 422: Incorrect or expired code (also for unknown addresses)

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 429: Too many incorrect attempts

Response schema: `#/components/schemas/ApiEnvelope`

