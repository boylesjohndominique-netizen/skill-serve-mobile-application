# Booking Refunds

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `PATCH /api/client/v1/bookings/{booking}/refund/confirm`

Confirm the returned payment reached you

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Confirmed; recorded as refunded on the booking

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Not the customer's booking

Response schema: `see openapi.json`

#### HTTP 404: Nothing to return on this booking

Response schema: `see openapi.json`

#### HTTP 409: The provider has not marked it returned

Response schema: `see openapi.json`

## `PATCH /api/client/v1/bookings/{booking}/refund/not-received`

SkillServe's team is alerted and the provider cannot take new bookings until it is settled.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `note` | yes | string, minLength=10, maxLength=1000 |

### Responses

#### HTTP 200: Reported

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Not the customer's booking

Response schema: `see openapi.json`

#### HTTP 404: Nothing to return on this booking

Response schema: `see openapi.json`

#### HTTP 409: The provider has not marked it returned

Response schema: `see openapi.json`

#### HTTP 422: Explain what happened (at least 10 characters)

Response schema: `see openapi.json`

## `GET /api/client/v1/bookings/{booking}/refund/proof`

The provider's proof of returning the payment

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: The image file

Response schema: `see openapi.json`

#### HTTP 403: Not the customer's booking

Response schema: `see openapi.json`

#### HTTP 404: No proof yet

Response schema: `see openapi.json`

## `POST /api/client/v1/provider/bookings/{booking}/refund`

Multipart: `image` (required screenshot of the GCash transfer) and optional `reference`. Allowed while the refund is `due` or after the customer reported it `not_received` (a new proof). Returns the booking.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Marked as returned; the customer is asked to confirm

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Not the provider's booking

Response schema: `see openapi.json`

#### HTTP 404: Nothing to return on this booking

Response schema: `see openapi.json`

#### HTTP 409: Not waiting to be returned

Response schema: `see openapi.json`

#### HTTP 422: Screenshot missing or invalid

Response schema: `see openapi.json`

## `GET /api/client/v1/provider/bookings/{booking}/refund/proof`

Your proof of returning the customer's payment

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: The image file

Response schema: `see openapi.json`

#### HTTP 403: Not the provider's booking

Response schema: `see openapi.json`

#### HTTP 404: No proof yet

Response schema: `see openapi.json`

