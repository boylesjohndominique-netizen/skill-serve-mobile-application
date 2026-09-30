# Payment Webhooks

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `POST /api/webhooks/paymongo`

Called by PayMongo, not by SkillServe clients. Verifies the `Paymongo-Signature` header (`t=<unix>,te=<test>,li=<live>`; HMAC-SHA256 of `<t>.<raw body>` under the webhook secret) against the raw request body, then applies `payment.paid` / `payment.failed` to the booking.

A booking is marked paid **here**, never from the customer's return redirect. Events are deduplicated by event id, because PayMongo redelivers.

**Authentication:** Public

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Event accepted (or acknowledged and ignored)

Response schema: `see openapi.json`

#### HTTP 401: Missing or invalid signature — the event is discarded

Response schema: `see openapi.json`

