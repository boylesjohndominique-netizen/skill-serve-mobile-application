# Notifications

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/notifications`

List notification history

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `status` | query | no | string (`pending`, `scheduled`, `sent`, `failed`) |
| `target` | query | no | string (`all`, `customers`, `providers`, `selected`) |
| `sort` | query | no | string (`created_at`, `scheduled_at`, `status`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |
| `page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Notification history

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

## `POST /api/notifications/announcements`

Send or schedule an announcement

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `title` | yes | string, maxLength=160 |
| `message` | yes | string, maxLength=10000 |
| `target` | yes | string, one of: `all`, `customers`, `providers`, `selected` |
| `recipient_ids` | no | array |
| `scheduled_at` | no | string, format=date-time |

### Responses

#### HTTP 201: Announcement created

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

## `DELETE /api/notifications/announcements/{announcement}`

Cancels a scheduled or pending announcement. Notifications already delivered stay in the recipients' inboxes.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `announcement` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Announcement removed

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Announcement not found

Response schema: `see openapi.json`

## `GET /api/notifications/recipients`

List announcement recipients

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `target` | query | yes | string (`all`, `customers`, `providers`, `selected`) |
| `search` | query | no | string |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Recipients

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

