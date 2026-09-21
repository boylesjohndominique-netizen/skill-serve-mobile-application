# Booking Disputes

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `PATCH /api/client/v1/bookings/{booking}/dispute`

Opens a case for administrators to review. Only a job in progress or completed can be disputed, and only once. The booking moves to the "disputed" status and the other party is notified.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `reason` | yes | string, minLength=10, maxLength=2000 |

### Responses

#### HTTP 200: Dispute raised

Response schema: `#/components/schemas/BookingDisputeEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not a party to this booking

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

#### HTTP 409: Already under dispute

Response schema: `see openapi.json`

#### HTTP 422: Booking cannot be disputed in its current status

Response schema: `see openapi.json`

## `POST /api/client/v1/bookings/{booking}/dispute/evidence`

Either party may add evidence while the dispute is pending or under investigation, up to 5 photos per dispute. Files are kept in private storage; only administrators reviewing the case can open them.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 201: Evidence attached

Response schema: `#/components/schemas/BookingDisputeEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not a party to this booking

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

#### HTTP 422: No open dispute, the evidence limit is reached, or the image is invalid

Response schema: `see openapi.json`

## `GET /api/client/v1/disputes`

List the disputes on the signed-in account's bookings

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `dispute_status` | query | no | string (`pending`, `investigated`, `resolved`, `rejected`, `closed`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Disputes

Response schema: `#/components/schemas/BookingDisputeListEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active customer or provider account required

Response schema: `see openapi.json`

#### HTTP 422: Invalid filter

Response schema: `see openapi.json`

