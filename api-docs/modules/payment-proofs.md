# Payment Proofs

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `POST /api/client/v1/bookings/{booking}/payment-proofs`

The customer's own GCash booking, once accepted, while something is still owed. `amount` is what was sent — a downpayment or up to everything still owed (`balance_due`). One proof waits for the provider at a time. Returns the booking with its `payment_proofs`.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 201: Proof sent; the provider is notified

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not the customer's booking

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

#### HTTP 409: Already paid, or a proof is still waiting

Response schema: `see openapi.json`

#### HTTP 422: Not a GCash booking, not accepted yet, or the amount is more than is owed

Response schema: `see openapi.json`

## `GET /api/client/v1/bookings/{booking}/payment-proofs/{proof}/image`

The screenshot of one of the customer's payment proofs

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |
| `proof` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: The image file

Response schema: `see openapi.json`

#### HTTP 403: Not the customer's booking

Response schema: `see openapi.json`

#### HTTP 404: No such proof on this booking

Response schema: `see openapi.json`

## `PATCH /api/client/v1/provider/bookings/{booking}/payment-proofs/{proof}/confirm`

Before or after the work. The amount is added to `amount_paid`; the booking becomes `partially_paid` (a downpayment) or `paid` once nothing is left, which also makes the commission due. Returns the booking.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |
| `proof` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Confirmed

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Not the provider's booking

Response schema: `see openapi.json`

#### HTTP 404: No such proof on this booking

Response schema: `see openapi.json`

#### HTTP 409: Already reviewed, or more than is still owed

Response schema: `see openapi.json`

## `GET /api/client/v1/provider/bookings/{booking}/payment-proofs/{proof}/image`

The screenshot of a customer's payment proof

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |
| `proof` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: The image file

Response schema: `see openapi.json`

#### HTTP 403: Not the provider's booking

Response schema: `see openapi.json`

#### HTTP 404: No such proof on this booking

Response schema: `see openapi.json`

## `PATCH /api/client/v1/provider/bookings/{booking}/payment-proofs/{proof}/reject`

Nothing is recorded as paid; the customer is told the reason and can send another.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |
| `proof` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `reason` | yes | string, minLength=3, maxLength=500 |

### Responses

#### HTTP 200: Rejected

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Not the provider's booking

Response schema: `see openapi.json`

#### HTTP 404: No such proof on this booking

Response schema: `see openapi.json`

#### HTTP 409: Already reviewed

Response schema: `see openapi.json`

#### HTTP 422: A reason is required

Response schema: `see openapi.json`

