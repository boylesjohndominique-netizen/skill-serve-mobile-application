# Client Authentication

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

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

#### HTTP 403: Inactive or unverified customer account

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

Register a customer account

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

#### HTTP 201: Registered and logged in; email verification is required before marketplace access

Response schema: `#/components/schemas/ClientAuthEnvelope`

#### HTTP 422: Validation error

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

