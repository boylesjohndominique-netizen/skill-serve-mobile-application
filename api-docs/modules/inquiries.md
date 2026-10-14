# Inquiries

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `POST /api/client/v1/inquiries`

Customers only. Returns the one conversation the customer has with this provider, creating it the first time. Only providers the marketplace shows can be messaged.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `provider_id` | yes | integer |

### Responses

#### HTTP 200: The conversation (kind `inquiry`)

Response schema: `#/components/schemas/ConversationEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified customer account required

Response schema: `see openapi.json`

#### HTTP 404: Provider not found or not listed

Response schema: `see openapi.json`

#### HTTP 422: Validation error, or the provider is the caller

Response schema: `see openapi.json`

#### HTTP 429: Too many conversations started

Response schema: `see openapi.json`

## `GET /api/client/v1/inquiries/{inquiry}/messages`

Oldest first. Opening it marks the messages addressed to the caller as read.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `inquiry` | path | yes | integer |
| `page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated messages

Response schema: `#/components/schemas/BookingMessageListEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Only the customer and the provider

Response schema: `see openapi.json`

#### HTTP 404: Conversation not found

Response schema: `see openapi.json`

## `POST /api/client/v1/inquiries/{inquiry}/messages`

Text, a photo, or both — exactly as in a booking chat: JSON for text, or multipart/form-data with `image` (JPG, PNG or WebP, at most 5 MB) and an optional `content`. An `Idempotency-Key` makes a retried send return the stored message.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `inquiry` | path | yes | integer |
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

#### HTTP 403: Only the customer and the provider

Response schema: `see openapi.json`

#### HTTP 404: Conversation not found

Response schema: `see openapi.json`

#### HTTP 409: Idempotency conflict

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

## `POST /api/client/v1/inquiries/{inquiry}/messages/read`

Mark the messages received in a conversation before booking as read

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `inquiry` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Marked read

Response schema: `#/components/schemas/MessagesMarkedReadEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Only the customer and the provider

Response schema: `see openapi.json`

#### HTTP 404: Conversation not found

Response schema: `see openapi.json`

## `GET /api/client/v1/inquiries/{inquiry}/messages/{message}/image`

Streamed from private storage to the two parties only.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `inquiry` | path | yes | integer |
| `message` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: The image file

Response schema: `see openapi.json`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Only the customer and the provider

Response schema: `see openapi.json`

#### HTTP 404: No such photo in this conversation

Response schema: `see openapi.json`

