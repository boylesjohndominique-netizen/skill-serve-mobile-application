# Commission Settings

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/commission-settings`

Read the commission rules

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: commission_rate (fallback %, when no tier matches), commission_block_min_amount (₱, 0 = any debt), commission_block_after_days (0 = off)

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: view commissions required

Response schema: `see openapi.json`

## `PUT /api/commission-settings`

Change the commission rules

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `commission_rate` | no | number, minimum=0, maximum=100 |
| `commission_block_min_amount` | no | number, minimum=0, maximum=1000000 |
| `commission_block_after_days` | no | integer, minimum=0, maximum=365 |

### Responses

#### HTTP 200: Saved

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: manage commissions required

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

