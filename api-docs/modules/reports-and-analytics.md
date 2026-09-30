# Reports and Analytics

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/analytics/reports`

Generate a report

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `type` | query | yes | string (`users`, `providers`, `services`, `bookings`, `reviews`, `activity`, `commissions`) |
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
| `type` | query | yes | string (`users`, `providers`, `services`, `bookings`, `reviews`, `activity`, `commissions`) |
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

## `GET /api/analytics/reports/general/export`

One .xlsx workbook: a Summary sheet (record counts per category with a status breakdown, and commission totals in pesos), then one sheet per report category (Users, Providers, Services, Bookings, Reviews, Activity, Commissions). The optional date range filters every category by creation date. Each category sheet is capped at 5,000 rows; the Summary sheet always shows the full counts.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `from` | query | no | string |
| `to` | query | no | string |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Excel workbook download

Response schema: `see openapi.json`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the export analytics permission

Response schema: `see openapi.json`

#### HTTP 422: Invalid date range

Response schema: `see openapi.json`

