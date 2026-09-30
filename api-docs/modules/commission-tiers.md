# Commission Tiers

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/commission-tiers`

Ordered by minimum amount so the bands read as a ladder. Amounts are Philippine pesos; both range bounds are inclusive and a null max_amount is the open-ended top band.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `is_active` | query | no | boolean |
| `sort` | query | no | string (`min_amount`, `percentage`, `name`, `created_at`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated commission tiers

```json
{
    "success": true,
    "message": "Commission tiers retrieved.",
    "data": [
        {
            "id": 2,
            "name": "Standard",
            "min_amount": "200.00",
            "max_amount": "499.99",
            "is_open_ended": false,
            "percentage": "10.00",
            "is_active": true,
            "created_at": "2026-09-24T08:00:00+00:00",
            "updated_at": "2026-09-24T08:00:00+00:00"
        }
    ],
    "errors": null,
    "meta": {
        "pagination": {
            "total": 1,
            "per_page": 15,
            "current_page": 1,
            "last_page": 1,
            "from": 1,
            "to": 1
        }
    }
}
```

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the view commissions permission

Response schema: `see openapi.json`

#### HTTP 422: Invalid filter values

Response schema: `see openapi.json`

## `POST /api/commission-tiers`

Both bounds are inclusive. Omit max_amount (or send null) to create the open-ended top band. The range may not overlap another enabled tier.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `name` | yes | string, maxLength=120 |
| `min_amount` | yes | number, format=float, minimum=0 |
| `max_amount` | no | number, format=float |
| `percentage` | yes | number, format=float, minimum=0, maximum=100 |
| `is_active` | no | boolean |

### Responses

#### HTTP 201: Tier created

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the manage commissions permission

Response schema: `see openapi.json`

#### HTTP 422: Validation failed, or the range overlaps an enabled tier

Response schema: `see openapi.json`

## `GET /api/commission-tiers/presets`

Ready-made tier sets that can replace the active tiers in one step.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Commission presets

```json
{
    "success": true,
    "message": "Commission presets retrieved.",
    "data": [
        {
            "key": "flat_10",
            "name": "Flat 10%",
            "description": "The same 10% on every booking, whatever its amount.",
            "tiers": [
                {
                    "name": "All bookings",
                    "min_amount": "0.00",
                    "max_amount": null,
                    "percentage": "10.00"
                }
            ]
        }
    ],
    "errors": null,
    "meta": null
}
```

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the view commissions permission

Response schema: `see openapi.json`

## `POST /api/commission-tiers/presets/{preset}/apply`

Retires every enabled tier and creates the preset's bands in their place, in one transaction. Disabled tiers are left alone. Bookings already made keep their own rate snapshot.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `preset` | path | yes | string |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Preset applied; the new tiers, lowest band first

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the manage commissions permission

Response schema: `see openapi.json`

#### HTTP 404: Preset not found

Response schema: `see openapi.json`

## `DELETE /api/commission-tiers/{commissionTier}`

Soft deletion. Bookings charged under this tier keep their rate snapshot, so past commissions never change.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `commissionTier` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 204: Tier retired

Response schema: `see openapi.json`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the manage commissions permission

Response schema: `see openapi.json`

#### HTTP 404: Tier not found

Response schema: `see openapi.json`

## `GET /api/commission-tiers/{commissionTier}`

Show a commission tier

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `commissionTier` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Commission tier

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the view commissions permission

Response schema: `see openapi.json`

#### HTTP 404: Tier not found

Response schema: `see openapi.json`

## `PATCH /api/commission-tiers/{commissionTier}`

Partial update. Disabling a tier (is_active=false) lifts the overlap rule for it, because a disabled band charges nobody. Bookings already charged under this tier keep their own rate snapshot and are unaffected.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `commissionTier` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `name` | no | string, maxLength=120 |
| `min_amount` | no | number, format=float, minimum=0 |
| `max_amount` | no | number, format=float |
| `percentage` | no | number, format=float, minimum=0, maximum=100 |
| `is_active` | no | boolean |

### Responses

#### HTTP 200: Tier updated

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the manage commissions permission

Response schema: `see openapi.json`

#### HTTP 404: Tier not found

Response schema: `see openapi.json`

#### HTTP 422: Validation failed, or the range overlaps an enabled tier

Response schema: `see openapi.json`

## `PUT /api/commission-tiers/{commissionTier}`

Partial update. Disabling a tier (is_active=false) lifts the overlap rule for it, because a disabled band charges nobody. Bookings already charged under this tier keep their own rate snapshot and are unaffected.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `commissionTier` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `name` | no | string, maxLength=120 |
| `min_amount` | no | number, format=float, minimum=0 |
| `max_amount` | no | number, format=float |
| `percentage` | no | number, format=float, minimum=0, maximum=100 |
| `is_active` | no | boolean |

### Responses

#### HTTP 200: Tier updated

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the manage commissions permission

Response schema: `see openapi.json`

#### HTTP 404: Tier not found

Response schema: `see openapi.json`

#### HTTP 422: Validation failed, or the range overlaps an enabled tier

Response schema: `see openapi.json`

