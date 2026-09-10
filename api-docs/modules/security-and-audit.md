# Security and Audit

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/audit-logs`

List audit logs

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `administrator_id` | query | no | integer |
| `action` | query | no | string |
| `module` | query | no | string |
| `view` | query | no | string (`all`, `login`, `security`) |
| `from` | query | no | string |
| `to` | query | no | string |
| `sort` | query | no | string (`created_at`, `id`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated audit logs

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

## `GET /api/audit-logs/administrators`

List audit log administrators

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Administrators

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

