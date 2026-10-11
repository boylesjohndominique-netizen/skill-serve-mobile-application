# Admin Authentication

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `DELETE /api/auth/me/photo`

Deletes the stored file; the header falls back to initials.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Photo removed

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

## `POST /api/auth/me/photo`

Replaces any previous photo, whose file is deleted. Only the signed-in account is changed; no id is accepted. Returns the administrator with `profile_photo_url`.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Photo saved

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 422: Not an image, or larger than 5 MB

Response schema: `see openapi.json`

