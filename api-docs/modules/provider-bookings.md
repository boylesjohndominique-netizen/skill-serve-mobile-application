# Provider Bookings

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/provider/bookings`

List the bookings placed with the authenticated provider

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

#### HTTP 200: Provider bookings

Response schema: `#/components/schemas/ProviderBookingListEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified provider access required

Response schema: `see openapi.json`

#### HTTP 404: Provider profile not found

Response schema: `see openapi.json`

#### HTTP 422: Invalid filter

Response schema: `see openapi.json`

## `GET /api/client/v1/provider/bookings/{booking}`

Get a booking placed with the authenticated provider

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Booking details

Response schema: `#/components/schemas/ProviderBookingEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not placed with this provider

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

## `PATCH /api/client/v1/provider/bookings/{booking}/complete`

Mark a job in progress as completed

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Job completed. Payment state is unchanged because no payment provider is called.

Response schema: `#/components/schemas/ProviderBookingEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not placed with this provider

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

#### HTTP 422: Only a job in progress can be completed

Response schema: `see openapi.json`

## `PATCH /api/client/v1/provider/bookings/{booking}/confirm`

Accept a pending booking request

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Booking confirmed

Response schema: `#/components/schemas/ProviderBookingEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not placed with this provider

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

#### HTTP 422: Only a pending booking can be accepted

Response schema: `see openapi.json`

## `PATCH /api/client/v1/provider/bookings/{booking}/decline`

Decline a pending booking request

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

#### HTTP 200: Booking declined. The booking is cancelled; payment state is unchanged and no external refund is processed.

Response schema: `#/components/schemas/ProviderBookingEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not placed with this provider

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

#### HTTP 422: Only a pending booking can be declined

Response schema: `see openapi.json`

## `PATCH /api/client/v1/provider/bookings/{booking}/start`

Start a confirmed job

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Job started

Response schema: `#/components/schemas/ProviderBookingEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not placed with this provider

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

#### HTTP 422: Only a confirmed booking can be started

Response schema: `see openapi.json`

