# Provider Commissions

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/provider/commission-remittances`

Newest first, with the status of each: pending (waiting for SkillServe to confirm), confirmed, or rejected with the reason.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated payments

Response schema: `see openapi.json`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, email-verified provider account required

Response schema: `see openapi.json`

#### HTTP 404: Provider profile not found

Response schema: `see openapi.json`

#### HTTP 422: Invalid per_page or page

Response schema: `see openapi.json`

## `POST /api/client/v1/provider/commission-remittances`

The commission is paid only with a QR Ph code now (POST /provider/commission-remittances/qr). This older way — GCash sent outside the app, then the reference typed in — always answers 410 so an outdated app tells the provider to update. Payments already submitted this way are still reviewed by an administrator.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, email-verified provider account required

Response schema: `see openapi.json`

#### HTTP 410: Retired; pay with a QR code instead

Response schema: `see openapi.json`

## `POST /api/client/v1/provider/commission-remittances/qr`

PayMongo creates a single-use dynamic QR Ph code for everything the provider owes right now; the amount is worked out by the server, never sent by the app. Scan it with GCash, Maya or a bank app. `qr_image` is the code as PayMongo returns it (a base-64 image to show as-is) and `expires_at` when it stops working (15 minutes; PayMongo is asked for `expiry_seconds` 900). The payment is confirmed only by PayMongo's signed webhook, and only when its amount and currency match; then the covered commissions are settled and the provider is notified.

Calling it again while a code is still payable returns that code (200) instead of making another. 503 when QR payments are not configured — pay by GCash reference instead.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 201: A new QR code

Response schema: `see openapi.json`

#### HTTP 200: The QR code already open

Response schema: `see openapi.json`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, email-verified provider account required

Response schema: `see openapi.json`

#### HTTP 404: Provider profile not found

Response schema: `see openapi.json`

#### HTTP 409: A GCash-reference payment is waiting for confirmation, or a QR code is still being prepared

Response schema: `see openapi.json`

#### HTTP 422: Nothing is owed, or the amount is outside what PayMongo accepts

Response schema: `see openapi.json`

#### HTTP 429: Too many attempts

Response schema: `see openapi.json`

#### HTTP 502: PayMongo could not create the code; try again

Response schema: `see openapi.json`

#### HTTP 503: QR payments are not configured

Response schema: `see openapi.json`

## `GET /api/client/v1/provider/commission-remittances/{commissionRemittance}`

For the app to follow a QR payment while it waits: `status` turns `confirmed` once PayMongo confirms it, or `expired` / `failed`. Only the provider's own payments; anyone else's is a 404.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `commissionRemittance` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: The payment

Response schema: `see openapi.json`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, email-verified provider account required

Response schema: `see openapi.json`

#### HTTP 404: Not found, or not this provider's

Response schema: `see openapi.json`

## `GET /api/client/v1/provider/commissions`

SkillServe's commission is included in the price the provider advertises, so on an on-hand job the provider collects the whole amount and owes the platform's share back. Once the block applies the provider cannot accept new jobs or publish services; declining, cancelling and finishing agreed work stay available. By default any unpaid commission blocks at once; an administrator can instead start the block at a minimum unpaid total (`block_threshold`) and/or after the oldest unpaid commission reaches an age (`block_deadline`, null when off). Whichever comes first blocks.

`eligible` is false with `reason` = `outstanding_commission` when the block applies.

`payment_account.qr_payments_available` says whether the provider can pay with a PayMongo QR Ph code for the exact amount (POST /provider/commission-remittances/qr) — the only way to pay. `latest_remittance` is the provider's most recent payment of either kind, or null: while it is `pending` they cannot start another (a QR one carries `qr_image` while it can be scanned); a `rejected` one carries `rejection_reason`.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Outstanding commissions and eligibility

```json
{
    "success": true,
    "message": "Commission summary retrieved.",
    "data": {
        "eligible": false,
        "reason": "outstanding_commission",
        "outstanding_total": "20.00",
        "outstanding_count": 1,
        "block_threshold": "0.00",
        "block_deadline": null,
        "currency": "PHP",
        "payment_account": {
            "qr_payments_available": true
        },
        "latest_remittance": null,
        "outstanding": [
            {
                "booking_number": "BK-AB12CD34EF56",
                "service": "Aircon Cleaning",
                "total_price": "200.00",
                "commission_rate": "10.00",
                "commission_amount": "20.00",
                "paid_at": "2026-09-24T08:00:00+00:00"
            }
        ]
    },
    "errors": null,
    "meta": []
}
```

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, email-verified provider account required

Response schema: `see openapi.json`

#### HTTP 404: Provider profile not found

Response schema: `see openapi.json`

