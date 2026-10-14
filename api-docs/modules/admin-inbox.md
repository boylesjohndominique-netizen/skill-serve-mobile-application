# Admin Inbox

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/inbox`

List the signed-in administrator's alerts, newest first

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `status` | query | no | string (`all`, `unread`) |
| `per_page` | query | no | integer |
| `page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated alerts

Response schema: `#/components/schemas/AdminAlertListEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Administrators only

Response schema: `see openapi.json`

#### HTTP 422: Invalid filter or pagination

Response schema: `see openapi.json`

## `POST /api/inbox/read-all`

Mark all of the administrator's alerts as read

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Alerts marked read

Response schema: `#/components/schemas/ClientReadAllEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Administrators only

Response schema: `see openapi.json`

## `GET /api/inbox/unread-count`

Count the signed-in administrator's unread alerts

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Unread count

Response schema: `#/components/schemas/ClientUnreadCountEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Administrators only

Response schema: `see openapi.json`

## `PATCH /api/inbox/{alert}/read`

Mark one of the administrator's own alerts as read

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `alert` | path | yes | string |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Alert marked read

Response schema: `#/components/schemas/AdminAlertEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Administrators only

Response schema: `see openapi.json`

#### HTTP 404: No such alert for this administrator

Response schema: `see openapi.json`

