# Provider Commissions

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/provider/commissions`

SkillServe's commission is included in the price the provider advertises, so on an on-hand job the provider collects the whole amount and owes the platform's share back. Once the block applies the provider cannot accept new jobs or publish services; declining, cancelling and finishing agreed work stay available. By default any unpaid commission blocks at once; an administrator can instead start the block at a minimum unpaid total (`block_threshold`) and/or after the oldest unpaid commission reaches an age (`block_deadline`, null when off). Whichever comes first blocks.

`eligible` is false with `reason` = `outstanding_commission` when the block applies.

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

