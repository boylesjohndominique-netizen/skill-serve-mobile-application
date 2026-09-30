# Identity Verifications

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/identity-verifications`

Filterable review queue. Searching matches the account's name or email — the card number is deliberately not searchable, because hashing a search term would turn this endpoint into a "does SkillServe know this ID?" oracle.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `status` | query | no | string (`unverified`, `pending`, `verified`, `rejected`) |
| `account_type` | query | no | string (`customer`, `provider`) |
| `search` | query | no | string |
| `sort` | query | no | string (`submitted_at`, `reviewed_at`, `created_at`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated submissions

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the view identity verifications permission

Response schema: `see openapi.json`

#### HTTP 422: Invalid filter values

Response schema: `see openapi.json`

## `GET /api/identity-verifications/{identityVerification}`

Show one submission with its documents and history

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `identityVerification` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Submission detail

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the view identity verifications permission

Response schema: `see openapi.json`

#### HTTP 404: Submission not found

Response schema: `see openapi.json`

## `PATCH /api/identity-verifications/{identityVerification}/approve`

Only a pending submission can be decided; a second decision returns 409. Approving starts the retention clock on the stored images (System Settings → Identity).

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `identityVerification` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `notes` | no | string, maxLength=1000 |

### Responses

#### HTTP 200: Identity verified

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the verify identities permission

Response schema: `see openapi.json`

#### HTTP 404: Submission not found

Response schema: `see openapi.json`

#### HTTP 409: Already reviewed

Response schema: `see openapi.json`

## `GET /api/identity-verifications/{identityVerification}/documents/{document}/download`

Streams the file from the private disk. The image is never reachable by URL, the document must belong to the submission in the path, and every request is authorised against the view permission.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `identityVerification` | path | yes | integer |
| `document` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: The file

Response schema: `see openapi.json`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the view identity verifications permission

Response schema: `see openapi.json`

#### HTTP 404: Not found, not part of this submission, or already purged

Response schema: `see openapi.json`

## `PATCH /api/identity-verifications/{identityVerification}/reject`

A reason is required and is shown to the account holder so they can correct the problem and resubmit. Only a pending submission can be decided.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `identityVerification` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `reason` | yes | string, minLength=3, maxLength=1000 |

### Responses

#### HTTP 200: Submission rejected

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Missing the reject identities permission

Response schema: `see openapi.json`

#### HTTP 404: Submission not found

Response schema: `see openapi.json`

#### HTTP 409: Already reviewed

Response schema: `see openapi.json`

#### HTTP 422: A reason is required

Response schema: `see openapi.json`

