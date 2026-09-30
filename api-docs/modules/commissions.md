# Commissions

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/commissions`

commission_status is pending (the job has not been paid for), outstanding (the provider holds SkillServe's share), settled, waived or voided. meta.totals carries the outstanding, settled and waived sums for the same provider and date filters.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `status` | query | no | string (`pending`, `outstanding`, `settled`, `waived`, `voided`) |
| `provider_id` | query | no | integer |
| `search` | query | no | string |
| `from` | query | no | string |
| `to` | query | no | string |
| `sort` | query | no | string (`paid_at`, `platform_fee`, `created_at`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated commissions with totals

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the view commissions permission

Response schema: `see openapi.json`

#### HTTP 422: Invalid filter values

Response schema: `see openapi.json`

## `PATCH /api/commissions/{booking}/settle`

Only an outstanding commission can be settled. The amount is always the commission snapshotted on the booking — it is never taken from the request, so a client cannot influence what SkillServe books as revenue.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `method` | yes | string, one of: `gcash`, `bank_transfer`, `cash`, `offset`, `other` |
| `reference` | no | string, maxLength=100 |
| `notes` | no | string, maxLength=1000 |

### Responses

#### HTTP 200: Settlement recorded

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the settle commissions permission

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

#### HTTP 409: The commission is not outstanding

Response schema: `see openapi.json`

#### HTTP 422: Validation failed

Response schema: `see openapi.json`

## `PATCH /api/commissions/{booking}/waive`

Only an outstanding commission can be waived, and a reason is always required — it is written to the audit log alongside the administrator who approved it.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `reason` | yes | string, minLength=3, maxLength=1000 |

### Responses

#### HTTP 200: Commission waived

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the settle commissions permission

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

#### HTTP 409: The commission is not outstanding

Response schema: `see openapi.json`

#### HTTP 422: A reason is required

Response schema: `see openapi.json`

