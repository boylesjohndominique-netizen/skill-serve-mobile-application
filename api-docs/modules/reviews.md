# Reviews

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/reviews`

List reviews

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `rating` | query | no | integer |
| `status` | query | no | string (`active`, `hidden`, `removed`) |
| `is_reported` | query | no | boolean |
| `provider_id` | query | no | integer |
| `service_id` | query | no | integer |
| `sort` | query | no | string (`rating`, `created_at`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated list of reviews

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

## `DELETE /api/reviews/{review}`

Soft-remove a review

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `review` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Review soft-removed. The record remains retained for audit and can be restored through Data Management.

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Not found

Response schema: `see openapi.json`

## `GET /api/reviews/{review}`

Get a review with its relationships

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `review` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Review details

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Not found

Response schema: `see openapi.json`

## `PATCH /api/reviews/{review}/hide`

Hide or restore a review

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `review` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `is_hidden` | yes | boolean |

Example request body:

```json
{
    "is_hidden": true
}
```

### Responses

#### HTTP 200: Review visibility updated

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Not found

Response schema: `see openapi.json`

