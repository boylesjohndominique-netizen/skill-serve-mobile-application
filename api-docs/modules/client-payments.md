# Client Payments

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `POST /api/client/v1/bookings/{booking}/pay`

**No booking is payable online today.** SkillServe is never in the payment path (ADR-021): both `gcash` and `on_hand` are settled directly between the customer and the provider, so every request to this endpoint is refused with a 422. A customer paying by GCash uses the `payment_instructions` on their own unpaid booking instead, and the provider confirms the payment afterwards.

The endpoint remains for a payment method routed to a gateway that collects money. In that case it is available on the customer's own unpaid booking once it is confirmed, active, completed or disputed; it returns `redirect_url` for the app to open, the booking becomes paid when the gateway calls the webhook — **not** when the customer returns — and tapping pay again returns the same in-flight payment rather than starting a second one.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |
| `Idempotency-Key` | header | no | string |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Payment started

```json
{
    "success": true,
    "message": "Payment started.",
    "data": {
        "redirect_url": "https://secure-authentication.paymongo.com/sources?id=src_...",
        "status": "awaiting_next_action",
        "amount": "200.00",
        "currency": "PHP"
    },
    "errors": null,
    "meta": []
}
```

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not the customer on this booking, or identity not verified

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

#### HTTP 409: Already paid

Response schema: `see openapi.json`

#### HTTP 422: Not payable online, or wrong status

Response schema: `see openapi.json`

#### HTTP 502: The payment provider refused the request

Response schema: `see openapi.json`

