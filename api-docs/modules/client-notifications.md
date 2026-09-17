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

