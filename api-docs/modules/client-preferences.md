# Client Preferences

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/preferences`

Returns the stored settings, creating them with the platform defaults on first call. Settings are account-scoped, so they follow the user to any device.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Current settings

Response schema: `#/components/schemas/ClientPreferenceEnvelope`

#### HTTP 401: Unauthenticated or expired token

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Token is not a client token or account is inactive

Response schema: `#/components/schemas/ApiEnvelope`

## `PUT /api/client/v1/preferences`

Partial update: send only the settings that changed.

These are enforced server-side, not just shown in the app:
 * the four notification flags gate whether that category is delivered at all;
 * `private_profile` removes a provider from public discovery and hides their services from the catalogue.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `booking_notifications` | no | boolean |
| `service_notifications` | no | boolean |
| `message_notifications` | no | boolean |
| `announcement_notifications` | no | boolean |
| `private_profile` | no | boolean |
| `activity_personalization` | no | boolean |
| `reduce_motion` | no | boolean |
| `theme` | no | string, one of: `light`, `dark`, `system` |

### Responses

#### HTTP 200: Updated settings

Response schema: `#/components/schemas/ClientPreferenceEnvelope`

#### HTTP 401: Unauthenticated or expired token

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 403: Token is not a client token or account is inactive

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Validation error

Response schema: `#/components/schemas/ApiEnvelope`

