# System Settings

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

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

