# System

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `POST /api/broadcasting/auth`

Called by the Reverb (Pusher protocol) client before subscribing to a private-* or presence-* channel. Also answers GET. Admin web and mobile tokens are both accepted; the channel rules are in routes/channels.php.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `socket_id` | yes | string |
| `channel_name` | yes | string |

### Responses

#### HTTP 200: Signed authorisation for the channel

```json
{
    "auth": "skillserve:3f2c\u2026"
}
```

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not allowed on this channel

Response schema: `see openapi.json`

## `GET /api/health`

Public. Reports whether the database and the upload storage (storage/app, the Render persistent disk in production) are usable. Never includes error details; those go to the server log. `otp` says whether the 6-digit codes can be sent (Twilio Verify configured, or a real mailer) without failing the check.

**Authentication:** Public

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Everything is up

```json
{
    "status": "ok",
    "timestamp": "2026-10-06T08:00:00+00:00",
    "services": {
        "database": {
            "status": "up"
        },
        "storage": {
            "status": "up"
        },
        "otp": {
            "status": "up",
            "driver": "twilio"
        }
    }
}
```

#### HTTP 503: Degraded: a service is down

```json
{
    "status": "degraded",
    "timestamp": "2026-10-06T08:00:00+00:00",
    "services": {
        "database": {
            "status": "down"
        },
        "storage": {
            "status": "up"
        },
        "otp": {
            "status": "up",
            "driver": "twilio"
        }
    }
}
```

