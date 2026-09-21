# Client Authentication

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `POST /api/client/v1/auth/cancel-registration`

Removes the parked registration (and, for accounts created before sign-ups were deferred, the unverified account itself) so the email can be used again straight away.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `email` | yes | string, format=email |
| `password` | yes | string, format=password |

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

## `POST /api/client/v1/auth/forgot-password`

Request a customer password reset email

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `email` | yes | string, format=email |

### Responses

#### HTTP 202: Reset request accepted without account enumeration

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation error

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/google`

Resolves the Google identity against existing accounts:
 * linked Google account, or an account owning the Google-verified email -> signed in (`registration_required: false`); the account is linked and its email marked verified.
 * no account -> nothing is created. Responds with `registration_required: true` plus a name/email draft for the sign-up form, which is submitted to POST /auth/google/register.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `id_token` | yes | string |

### Responses

#### HTTP 200: Signed in, or a sign-up is required

Response schema: `#/components/schemas/ClientGoogleAuthEnvelope`

#### HTTP 401: Invalid Google token

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Account not active, or the email belongs to an administrator

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation error

Response schema: `#/components/schemas/ApiEnvelope`

## `POST /api/client/v1/auth/google/register`

Creates the customer or provider account for a Google identity that has none, and signs it in. The ID token is re-verified, so the email always comes from Google. Until this call succeeds nothing is written, so abandoning the form leaves no account behind.

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

### Responses

#### HTTP 201: Account created and signed in

Response schema: `#/components/schemas/ClientAuthEnvelope`

#### HTTP 401: Invalid or expired Google token

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Account not active, or the email belongs to an administrator

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation error

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
| `phone` | no | string, maxLength=30 |
| `address` | no | string, maxLength=500 |

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

Parks the sign-up and emails a 6-digit code. The `users` row is created by POST /auth/verify-otp, so abandoning verification leaves the address free to register again.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `first_name` | yes | string, maxLength=255 |
| `last_name` | yes | string, maxLength=255 |
| `email` | yes | string, format=email |
| `password` | yes | string, format=password, minLength=8 |
| `password_confirmation` | yes | string, format=password |

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

Same deferred flow as customer registration: the provider account and its pending `provider_profiles` row are created by POST /auth/verify-otp.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `first_name` | yes | string, maxLength=255 |
| `last_name` | yes | string, maxLength=255 |
| `email` | yes | string, format=email |
| `password` | yes | string, format=password, minLength=8 |
| `password_confirmation` | yes | string, format=password |
| `business_name` | no | string, maxLength=255 |
| `specialization` | yes | string, maxLength=255 |
| `experience_years` | no | integer, minimum=0 |
| `bio` | no | string, maxLength=5000 |

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

## `POST /api/client/v1/auth/reset-password`

Complete a customer password reset

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

For a sign-up started by /auth/register or /auth/register-provider this creates the account and returns a session. Accounts registered before sign-ups were deferred are simply marked verified and signed in.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `email` | yes | string, format=email |
| `code` | yes | string, minLength=6, maxLength=6 |

### Responses

#### HTTP 200: Email verified, account created and signed in

Response schema: `#/components/schemas/ClientAuthEnvelope`

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

