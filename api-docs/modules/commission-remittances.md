# Commission Remittances

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/commission-remittances`

Each item carries the GCash reference to look for in SkillServe's GCash history, the amount owed and the amount the provider says they sent, the provider's own GCash account (the expected sender), and the bookings a confirmation would settle. `other_claims_count` above 0 means another provider has a pending or confirmed claim on the same reference — check the sender before confirming. Pass status=pending for the review queue.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `status` | query | no | string (`pending`, `confirmed`, `rejected`, `expired`, `failed`) |
| `provider_id` | query | no | integer |
| `search` | query | no | string |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated payments

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the view commissions permission

Response schema: `see openapi.json`

#### HTTP 422: Invalid filter values

Response schema: `see openapi.json`

## `PATCH /api/commission-remittances/{commissionRemittance}/confirm`

Only a pending payment can be confirmed. Settles every booking it covered that is still outstanding, recording method gcash and the payment's reference, and tells the provider. A booking waived, voided or settled by hand meanwhile is skipped. A reference pays once: confirming a second claim on an already-confirmed reference is refused with 409.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `commissionRemittance` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `notes` | no | string, maxLength=1000 |

### Responses

#### HTTP 200: Payment confirmed

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the settle commissions permission

Response schema: `see openapi.json`

#### HTTP 404: Payment not found

Response schema: `see openapi.json`

#### HTTP 409: The payment has already been reviewed, or its reference has already been confirmed on another claim

Response schema: `see openapi.json`

#### HTTP 422: Validation failed

Response schema: `see openapi.json`

## `GET /api/commission-remittances/{commissionRemittance}/proof`

Served from private storage after checking the view commissions permission, and logged to the audit trail. 404 when no receipt was attached, or once it was deleted 180 days after the payment was decided.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `commissionRemittance` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: The receipt image

Response schema: `see openapi.json`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the view commissions permission

Response schema: `see openapi.json`

#### HTTP 404: Payment or receipt not found

Response schema: `see openapi.json`

## `PATCH /api/commission-remittances/{commissionRemittance}/reject`

Only a pending payment can be rejected, and a reason is required — the provider is shown it and may submit again. Nothing is settled.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `commissionRemittance` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `reason` | yes | string, minLength=3, maxLength=1000 |

### Responses

#### HTTP 200: Payment rejected

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the settle commissions permission

Response schema: `see openapi.json`

#### HTTP 404: Payment not found

Response schema: `see openapi.json`

#### HTTP 409: The payment has already been reviewed

Response schema: `see openapi.json`

#### HTTP 422: Validation failed

Response schema: `see openapi.json`

