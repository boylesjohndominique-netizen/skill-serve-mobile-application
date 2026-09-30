# Client Bookings

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/bookings`

List the authenticated customer bookings

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `status` | query | no | string (`pending`, `confirmed`, `active`, `completed`, `cancelled`, `disputed`) |
| `sort` | query | no | string (`created_at`, `scheduled_date`, `status`, `total_price`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Customer bookings

Response schema: `#/components/schemas/ClientBookingListEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified client access required

Response schema: `see openapi.json`

#### HTTP 422: Invalid filter

Response schema: `see openapi.json`

## `POST /api/client/v1/bookings`

Requires a verified National ID once System Settings → Identity turns the requirement on for this account; otherwise 403 with `errors.identity`. Call `/transaction-eligibility` to find out in advance.

**Payment methods changed.** SkillServe now supports `on_hand` and `gcash` only. `cash` is a DEPRECATED alias for `on_hand` and is stored as `on_hand`. `credit_card`, `debit_card`, `bank_transfer` and `paypal` were removed and are now rejected with 422 — clients offering them must be updated.

The commission is included in the advertised price, so `total_price` is what the customer pays and is unchanged by it.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `Idempotency-Key` | header | no | string |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `service_id` | yes | integer |
| `scheduled_date` | yes | string, format=date-time |
| `scheduled_end_date` | no | string, format=date-time |
| `client_notes` | no | string, maxLength=2000 |
| `payment_method` | no | string, one of: `on_hand`, `gcash`, `cash` |

### Responses

#### HTTP 201: Booking created

Response schema: `#/components/schemas/ClientBookingEnvelope`

#### HTTP 200: Existing booking returned for a repeated idempotency key

Response schema: `#/components/schemas/ClientBookingEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified client access required

Response schema: `see openapi.json`

#### HTTP 409: Idempotency or provider schedule conflict

Response schema: `see openapi.json`

#### HTTP 422: Unavailable or unbookable service

Response schema: `see openapi.json`

## `GET /api/client/v1/bookings/{booking}`

Get an owned booking

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Booking details

Response schema: `#/components/schemas/ClientBookingEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not owned by the customer or email is unverified

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

## `PATCH /api/client/v1/bookings/{booking}/cancel`

Cancel an owned pending or confirmed booking without processing a refund

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `reason` | no | string, maxLength=1000 |

### Responses

#### HTTP 200: Booking cancelled. Unpaid remains unpaid; paid state is unchanged and no external refund is processed.

Response schema: `#/components/schemas/ClientBookingEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not owned by the customer

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

#### HTTP 422: Booking cannot be cancelled

Response schema: `see openapi.json`

## `PATCH /api/client/v1/bookings/{booking}/reschedule`

Re-runs the provider hours and overlap checks for the new window. A confirmed booking returns to pending for the provider to accept again, and the provider is notified. Without scheduled_end_date the booking keeps its current length.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `scheduled_date` | yes | string, format=date-time |
| `scheduled_end_date` | no | string, format=date-time |

### Responses

#### HTTP 200: Booking rescheduled; status is now pending

Response schema: `#/components/schemas/ClientBookingEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not owned by the customer

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

#### HTTP 409: The new time overlaps another booking for this provider

Response schema: `see openapi.json`

#### HTTP 422: Validation error, same time as now, outside the provider hours, or the booking is no longer pending/confirmed

Response schema: `see openapi.json`

