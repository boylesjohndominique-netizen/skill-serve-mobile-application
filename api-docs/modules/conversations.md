# Conversations

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/conversations`

Threads the account can message on that already carry at least one message, newest activity first: booking chats, and with `include_inquiries=1` also conversations before a booking (`kind: inquiry`). Reading this list does not mark anything as read.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `per_page` | query | no | integer |
| `page` | query | no | integer |
| `include_inquiries` | query | no | boolean |

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

