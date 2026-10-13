# Client Notifications

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/notifications`

List the authenticated customer notification inbox

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `per_page` | query | no | integer |
| `page` | query | no | integer |
| `archived` | query | no | boolean |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated notification inbox

Response schema: `#/components/schemas/ClientNotificationListEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified customer or provider account required

Response schema: `see openapi.json`

#### HTTP 422: Invalid pagination

Response schema: `see openapi.json`

## `POST /api/client/v1/notifications/archive`

Moves them out of the feed (and the unread count) into the archive, marking them read. Ids that are not the user's own are ignored. Other open sessions are told on the user's private channel (`client.notifications.changed`).

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `ids` | yes | array |

### Responses

#### HTTP 200: How many were archived (updated_count)

Response schema: `#/components/schemas/ClientReadAllEnvelope`

#### HTTP 403: Active, verified customer or provider account required

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

## `GET /api/client/v1/notifications/background`

Authenticated with the background token only. Returns up to 10 unread notifications created at or after `after`, oldest first; without `after`, the last 24 hours. Muted categories are never stored, so everything returned may be shown.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `after` | query | no | string |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Pending notifications (same shape as the feed)

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated or token expired

Response schema: `see openapi.json`

#### HTTP 403: Not a background token, or the account is inactive

Response schema: `see openapi.json`

#### HTTP 422: Invalid `after`

Response schema: `see openapi.json`

## `POST /api/client/v1/notifications/background-token`

Called by the app after sign-in. The token can only call GET /notifications/background; it never refreshes and ends when the user signs out or changes their password. Up to five are kept per account (one per device).

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 201: Background token issued

```json
{
    "success": true,
    "message": "Background token issued.",
    "data": {
        "token": "42|\u2026",
        "expires_at": "2027-09-21T10:00:00+00:00"
    },
    "errors": null,
    "meta": []
}
```

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified mobile account with a full session token required

Response schema: `see openapi.json`

## `POST /api/client/v1/notifications/delete`

Ids that are not the user's own are ignored, never deleted. Other open sessions are told (`client.notifications.changed`).

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `ids` | yes | array |

### Responses

#### HTTP 200: How many were deleted (updated_count)

Response schema: `#/components/schemas/ClientReadAllEnvelope`

#### HTTP 403: Active, verified customer or provider account required

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

## `POST /api/client/v1/notifications/read-all`

Mark all owned notifications as read

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Notifications marked read

Response schema: `#/components/schemas/ClientReadAllEnvelope`

#### HTTP 403: Active, verified customer or provider account required

Response schema: `see openapi.json`

## `POST /api/client/v1/notifications/unarchive`

Move archived notifications back to the feed

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `ids` | yes | array |

### Responses

#### HTTP 200: How many were restored (updated_count)

Response schema: `#/components/schemas/ClientReadAllEnvelope`

#### HTTP 403: Active, verified customer or provider account required

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

## `GET /api/client/v1/notifications/unread-count`

Count unread customer notifications

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Unread count

Response schema: `#/components/schemas/ClientUnreadCountEnvelope`

#### HTTP 403: Active, verified customer or provider account required

Response schema: `see openapi.json`

## `DELETE /api/client/v1/notifications/{notification}`

Delete one notification

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `notification` | path | yes | string |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Deleted

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Active, verified customer or provider account required

Response schema: `see openapi.json`

#### HTTP 404: Notification not found

Response schema: `see openapi.json`

## `PATCH /api/client/v1/notifications/{notification}/read`

Mark one owned notification as read

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `notification` | path | yes | string |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Notification marked read

Response schema: `#/components/schemas/ClientNotificationEnvelope`

#### HTTP 403: Active, verified customer or provider account required

Response schema: `see openapi.json`

#### HTTP 404: Notification not found

Response schema: `see openapi.json`

