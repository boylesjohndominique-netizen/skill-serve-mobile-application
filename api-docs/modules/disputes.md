# Disputes

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/disputes`

List booking disputes

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `status` | query | no | string (`pending`, `investigated`, `resolved`, `rejected`, `closed`) |
| `provider_id` | query | no | integer |
| `client_id` | query | no | integer |
| `service_id` | query | no | integer |
| `date_from` | query | no | string |
| `date_to` | query | no | string |
| `sort` | query | no | string (`booking_number`, `created_at`, `disputed_at`, `dispute_status`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated disputes

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

## `GET /api/disputes/{booking}`

View dispute details

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Dispute details

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Not found

Response schema: `see openapi.json`

#### HTTP 422: Booking has no dispute

Response schema: `see openapi.json`

## `PATCH /api/disputes/{booking}/close`

Close a resolved dispute

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `note` | no | string, maxLength=2000 |

### Responses

#### HTTP 200: Dispute closed

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation or state error

Response schema: `see openapi.json`

## `GET /api/disputes/{booking}/evidence/{evidence}`

Served from private storage after checking the view-disputes permission. The evidence id comes from the booking's dispute_evidence list.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |
| `evidence` | path | yes | string |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: The evidence file

Response schema: `see openapi.json`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the view-disputes permission

Response schema: `see openapi.json`

#### HTTP 404: Evidence or file not found

Response schema: `see openapi.json`

## `GET /api/disputes/{booking}/history`

View paginated dispute history

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |
| `page` | query | no | integer |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated dispute history

Response schema: `#/components/schemas/ApiEnvelope`

## `PATCH /api/disputes/{booking}/investigate`

Investigate a dispute

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Dispute under investigation

Response schema: `#/components/schemas/ApiEnvelope`

## `PATCH /api/disputes/{booking}/notes`

Add dispute notes

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `note` | yes | string, maxLength=2000 |

### Responses

#### HTTP 200: Note added

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation or state error

Response schema: `see openapi.json`

## `PATCH /api/disputes/{booking}/reject`

Reject a dispute

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `note` | no | string, maxLength=2000 |

### Responses

#### HTTP 200: Dispute rejected

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation or state error

Response schema: `see openapi.json`

## `PATCH /api/disputes/{booking}/resolve`

Resolve a dispute

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `resolution` | yes | string, maxLength=2000 |

### Responses

#### HTTP 200: Dispute resolved

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation or state error

Response schema: `see openapi.json`

