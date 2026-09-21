# Client Platform

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/platform`

Public. Stays available during maintenance mode, so the app can tell when the platform is back. Policy texts are the ones administrators write in System Settings → Platform policies (empty until written).

**Authentication:** Public

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Platform information

```json
{
    "success": true,
    "message": "Platform information retrieved.",
    "data": {
        "platform_name": "SkillServe",
        "platform_description": "",
        "support_email": "support@skillserve.ph",
        "maintenance_mode": false,
        "provider_registration_enabled": true,
        "booking": {
            "booking_enabled": true,
            "cancellation_window_hours": 24,
            "client_cancellation_fee_percent": 0,
            "provider_cancellation_fee_percent": 0
        },
        "policies": {
            "terms_of_service": "\u2026",
            "privacy_policy": "\u2026",
            "community_guidelines": "\u2026"
        }
    },
    "errors": null,
    "meta": []
}
```

