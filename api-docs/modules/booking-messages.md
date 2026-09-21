# Booking Messages

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/bookings/{booking}/messages`

List messages for a booking participant

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |
| `page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated booking messages

Response schema: `#/components/schemas/BookingMessageListEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Booking participant access required

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

## `POST /api/client/v1/bookings/{booking}/messages`

Send a message to the other booking participant

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |
| `Idempotency-Key` | header | no | string |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `content` | yes | string, maxLength=5000 |

### Responses

#### HTTP 201: Message sent

Response schema: `#/components/schemas/BookingMessageEnvelope`

#### HTTP 200: Existing message returned for a repeated idempotency key

Response schema: `#/components/schemas/BookingMessageEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Booking participant access required

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

#### HTTP 409: Idempotency conflict

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

## `POST /api/client/v1/bookings/{booking}/messages/read`

For an open conversation that already shows a pushed message: clears its unread state without re-reading the thread, and returns the account's remaining unread total for the Messages badge.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Marked read

Response schema: `#/components/schemas/MessagesMarkedReadEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Booking participant access required

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

