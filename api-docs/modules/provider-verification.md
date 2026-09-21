# Provider Verification

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/provider/verification`

verification_status is unverified, pending, verified, rejected or additional_info_required. can_submit tells the app whether to offer an upload. The request carries the rejection reason or the information an administrator asked for.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Verification state

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified-email provider account required

Response schema: `see openapi.json`

#### HTTP 404: Provider profile not found

Response schema: `see openapi.json`

## `POST /api/client/v1/provider/verification`

Allowed while unverified, rejected (starts a new request) or additional_info_required (adds documents to the same request — the answer to an information request). Moves the provider to pending review. Files are private: JPG, PNG or PDF, up to 10 MB each, at most 5 per submission.

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

#### HTTP 403: Active, verified-email provider account required

Response schema: `see openapi.json`

#### HTTP 404: Provider profile not found

Response schema: `see openapi.json`

#### HTTP 422: Invalid files, or already pending / verified

Response schema: `see openapi.json`

