# Data Management

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/data-management/archives`

List archived records

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `resource_type` | query | no | string (`services`) |
| `page` | query | no | integer |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated archived records

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

## `POST /api/data-management/archives`

Archive a record

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `resource_type` | yes | string, one of: `services` |
| `resource_id` | yes | integer, minimum=1 |

### Responses

#### HTTP 201: Record archived

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

## `POST /api/data-management/archives/{archive}/restore`

Restore an archived record

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `archive` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Record restored

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Archive not found

Response schema: `see openapi.json`

## `GET /api/data-management/deleted`

Returns a database-paginated union of soft-deleted records; records are not loaded into an in-memory capped collection.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `resource_type` | query | no | string (`users`, `services`, `bookings`, `reviews`, `reports`, `messages`, `service_categories`, `service_subcategories`) |
| `page` | query | no | integer |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated deleted records

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

## `DELETE /api/data-management/deleted/{type}/{id}`

Permanently delete a record

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `type` | path | yes | string (`messages`, `reports`) |
| `id` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 204: Record permanently deleted

Response schema: `see openapi.json`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Record not found

Response schema: `see openapi.json`

#### HTTP 422: Record type cannot be permanently deleted

Response schema: `see openapi.json`

## `POST /api/data-management/deleted/{type}/{id}/restore`

Restore a deleted record

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `type` | path | yes | string (`users`, `services`, `bookings`, `reviews`, `reports`, `messages`, `service_categories`, `service_subcategories`) |
| `id` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Record restored

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Record not found

Response schema: `see openapi.json`

## `GET /api/data-management/export`

Export system data as CSV

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `type` | query | yes | string (`users`, `providers`, `services`, `bookings`, `reviews`, `activity`) |
| `search` | query | no | string |
| `status` | query | no | string |
| `from` | query | no | string |
| `to` | query | no | string |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: CSV export

Response schema: `see openapi.json`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

