# Client Favorites

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/favorites`

Most recently saved first. Providers who are no longer publicly listed (suspended, unverified, private) are left out.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `per_page` | query | no | integer |
| `page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Saved providers

Response schema: `#/components/schemas/ClientProviderListEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified customer account required

Response schema: `see openapi.json`

#### HTTP 422: Invalid pagination parameters

Response schema: `see openapi.json`

## `DELETE /api/client/v1/favorites/{provider}`

Idempotent: removing a provider that is not saved also succeeds.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `provider` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Provider removed

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified customer account required

Response schema: `see openapi.json`

#### HTTP 404: Provider not found

Response schema: `see openapi.json`

## `PUT /api/client/v1/favorites/{provider}`

Idempotent: saving a provider that is already saved succeeds without a duplicate.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `provider` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Provider saved

Response schema: `#/components/schemas/ClientProviderEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified customer account required

Response schema: `see openapi.json`

#### HTTP 404: Provider not found or not publicly listed

Response schema: `see openapi.json`

