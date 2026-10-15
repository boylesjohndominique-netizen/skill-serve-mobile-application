# Identity Verification

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/identity-verification`

status is unverified, pending, verified or rejected. can_submit tells the app whether to offer the form. Only the last four digits of the card number are ever returned.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Verification state

```json
{
    "success": true,
    "message": "Identity verification status retrieved.",
    "data": {
        "status": "rejected",
        "can_submit": true,
        "id_number_last4": "4821",
        "full_name": "Juan Dela Cruz",
        "birthdate": "1995-04-02",
        "submitted_at": "2026-09-20T02:11:00+00:00",
        "reviewed_at": "2026-09-21T06:40:00+00:00",
        "rejection_reason": "The photo of the back of the card was unreadable.",
        "documents": []
    },
    "errors": null,
    "meta": []
}
```

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, email-verified account required

Response schema: `see openapi.json`

## `POST /api/client/v1/identity-verification`

Allowed while unverified or rejected; a pending or verified account is refused with 422. The card number is normalised to 16 digits, so grouped input is accepted.

One National ID can verify one provider account and one customer account. Submitting an ID that another account of the same type already holds (pending or verified) returns 422 — `A provider account already uses this National ID.` (or `customer`) — without revealing which account holds it. A rejected submission does not hold the ID. An ID becomes available again once the original account is permanently deleted.

Files are private (JPG, PNG or PDF, up to 10 MB each) and are never served directly; an administrator opens them through an authorised download. A photo of the front or back must be at least 800 × 500 pixels (either orientation), or that file gets a 422 asking for a retake.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 201: Submitted; status is now pending

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, email-verified account required

Response schema: `see openapi.json`

#### HTTP 422: Validation failed, another account of the same type (provider or customer) already uses the ID, or the account is already pending or verified

Response schema: `see openapi.json`

#### HTTP 429: Too many submissions

Response schema: `see openapi.json`

