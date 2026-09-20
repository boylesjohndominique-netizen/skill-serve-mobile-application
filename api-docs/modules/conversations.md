# Conversations

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/conversations`

Bookings the account can message on that already carry at least one message, newest activity first. Reading this list does not mark anything as read.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Conversations

Response schema: `#/components/schemas/ConversationListEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified customer or provider account required

Response schema: `see openapi.json`

#### HTTP 422: Invalid pagination

Response schema: `see openapi.json`

## `GET /api/client/v1/conversations/unread-count`

Count every unread message addressed to the signed-in account

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Unread message count

Response schema: `#/components/schemas/UnreadMessageCountEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified customer or provider account required

Response schema: `see openapi.json`

