# Reports and Analytics

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/analytics/reports`

Generate a report

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `type` | query | yes | string (`users`, `providers`, `services`, `bookings`, `reviews`, `activity`) |
| `search` | query | no | string |
| `status` | query | no | string |
| `from` | query | no | string |
| `to` | query | no | string |
| `sort` | query | no | string (`created_at`, `id`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Report rows

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

## `GET /api/analytics/reports/export`

Export a report to CSV

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `type` | query | yes | string (`users`, `providers`, `services`, `bookings`, `reviews`, `activity`) |
| `search` | query | no | string |
| `status` | query | no | string |
| `from` | query | no | string |
| `to` | query | no | string |
| `sort` | query | no | string (`created_at`, `id`) |
| `direction` | query | no | string (`asc`, `desc`) |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: CSV file

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

