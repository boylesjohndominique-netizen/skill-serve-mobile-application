# Transaction Eligibility

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/transaction-eligibility`

Returns the same decision the protected endpoints enforce, so the app can show the right prompt rather than a bare 403.

`reason` is null when eligible, otherwise one of `identity_unverified`, `identity_pending`, `identity_rejected`, `outstanding_commission` or `no_provider_profile`. Providers additionally receive their outstanding commission total, `block_threshold` (the unpaid total at which the commission block starts; `0.00` means any debt) and `block_deadline` (when the oldest unpaid commission starts blocking by age, or null when that trigger is off or nothing is owed).

`identity_required` reflects System Settings → Identity: accounts created before the grandfathering date are not required to verify and report `false`.

This endpoint is advisory. The backend remains authoritative: the mobile app and the admin web both inherit these rules from the API rather than implementing them separately.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Eligibility

```json
{
    "success": true,
    "message": "Eligibility retrieved.",
    "data": {
        "account_type": "provider",
        "eligible": false,
        "reason": "identity_unverified",
        "identity_status": "unverified",
        "identity_required": true,
        "outstanding_total": "0.00",
        "outstanding_count": 0,
        "block_threshold": "0.00",
        "block_deadline": null
    },
    "errors": null,
    "meta": []
}
```

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, email-verified account required

Response schema: `see openapi.json`

