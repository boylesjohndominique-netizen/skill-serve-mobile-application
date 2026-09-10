# Provider Recognition

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/provider-recognition/badges`

List provider badges

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `is_active` | query | no | boolean |
| `page` | query | no | integer |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated badges

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

## `POST /api/provider-recognition/badges`

Create a provider badge

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `name` | yes | string, maxLength=100 |
| `slug` | yes | string, maxLength=120 |
| `description` | no | string |
| `color` | no | string, maxLength=30 |
| `is_active` | no | boolean |

### Responses

#### HTTP 201: Badge created

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

## `DELETE /api/provider-recognition/badges/{badge}`

Delete a provider badge

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `badge` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Badge deleted

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Badge not found

Response schema: `see openapi.json`

## `PUT /api/provider-recognition/badges/{badge}`

Update a provider badge

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `badge` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `name` | no | string, maxLength=100 |
| `slug` | no | string, maxLength=120 |
| `description` | no | string |
| `color` | no | string, maxLength=30 |
| `is_active` | no | boolean |

### Responses

#### HTTP 200: Badge updated

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Badge not found

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

## `GET /api/provider-recognition/providers`

List recognition providers

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `badge_id` | query | no | integer |
| `is_featured` | query | no | boolean |
| `sort` | query | no | string (`created_at`, `average_rating`, `total_bookings`, `total_reviews`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `page` | query | no | integer |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated recognition providers

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

## `POST /api/provider-recognition/providers/{provider}/badges`

Assign a badge to a provider

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `provider` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `badge_id` | yes | integer, minimum=1 |

### Responses

#### HTTP 200: Badge assigned

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

## `DELETE /api/provider-recognition/providers/{provider}/badges/{badge}`

Remove a badge from a provider

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `provider` | path | yes | integer |
| `badge` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Badge removed

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Provider or badge not found

Response schema: `see openapi.json`

## `PATCH /api/provider-recognition/providers/{provider}/featured`

Feature or unfeature a provider

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `provider` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `is_featured` | yes | boolean |

### Responses

#### HTTP 200: Featured status updated

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

## `GET /api/provider-recognition/top-rated`

List top-rated providers

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `badge_id` | query | no | integer |
| `is_featured` | query | no | boolean |
| `min_rating` | query | no | number |
| `page` | query | no | integer |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated top-rated providers

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

