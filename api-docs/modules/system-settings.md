# System Settings

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/appearance`

Public, so the sign-in page is themed too. `primary_color` is a #RRGGBB hex, or empty for the built-in SkillServe green; `font_family` is one of system, inter, poppins, roboto, outfit, nunito, open_sans, montserrat; `font_size` is small, medium, large or extra_large. Set in System Settings → Appearance.

**Authentication:** Public

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: The theme

```json
{
    "success": true,
    "message": "Appearance retrieved.",
    "data": {
        "primary_color": "#03833E",
        "font_family": "poppins",
        "font_size": "medium"
    },
    "errors": null,
    "meta": []
}
```

## `GET /api/settings`

meta.read_only lists "group.name" settings shown for information only (for example general.timezone, which follows the server APP_TIMEZONE).

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Grouped system settings

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

## `PUT /api/settings`

Updates only known, unlocked settings. The system.session_timeout_minutes value controls new administrator token expiry and is enforced for existing administrator bearer tokens.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `general` | no | object |
| `marketplace` | no | object |
| `booking` | no | object |
| `notifications` | no | object |
| `policies` | no | object |
| `system` | no | object |

Example request body:

```json
{
    "general": {
        "platform_name": "SkillServe",
        "support_email": "support@skillserve.test"
    },
    "booking": {
        "booking_enabled": true
    },
    "system": {
        "session_timeout_minutes": 1440
    }
}
```

### Responses

#### HTTP 200: Settings updated

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

