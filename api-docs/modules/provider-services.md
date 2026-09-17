# Provider Services

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/provider/profile`

Get the authenticated provider's own profile (any verification state)

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Provider profile

Response schema: `#/components/schemas/ProviderProfileEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified-email provider account required

Response schema: `see openapi.json`

## `GET /api/client/v1/provider/services`

List the authenticated provider's services (all approval states)

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `approval_status` | query | no | string (`pending`, `approved`, `rejected`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Provider services

Response schema: `#/components/schemas/ProviderServiceListEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified provider account required

Response schema: `see openapi.json`

#### HTTP 422: Invalid filters

Response schema: `see openapi.json`

## `POST /api/client/v1/provider/services`

Creates the service as draft/pending. It becomes visible to customers only after an administrator approves it. Amounts are in Philippine pesos (PHP). Requires a verified provider profile.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

See the request schema in `openapi.json`.

Example request body:

```json
{
    "title": "Aircon Cleaning",
    "description": "Split-type aircon deep cleaning.",
    "category_id": 1,
    "subcategory_id": null,
    "price": 1500,
    "price_type": "fixed",
    "duration": "2 hours",
    "location": "Quezon City"
}
```

### Responses

#### HTTP 201: Service submitted (pending approval)

Response schema: `#/components/schemas/ProviderServiceEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not a provider account, or provider not yet verified

Response schema: `see openapi.json`

#### HTTP 422: Validation failed

Response schema: `see openapi.json`

## `DELETE /api/client/v1/provider/services/{service}`

Delete an owned service

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `service` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Service deleted

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified provider account required

Response schema: `see openapi.json`

#### HTTP 404: Service not found or owned by another provider

Response schema: `see openapi.json`

#### HTTP 409: Service has pending, confirmed or active bookings

Response schema: `see openapi.json`

## `GET /api/client/v1/provider/services/{service}`

Get one of the provider's own services

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `service` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Service

Response schema: `#/components/schemas/ProviderServiceEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified provider account required

Response schema: `see openapi.json`

#### HTTP 404: Service not found or owned by another provider

Response schema: `see openapi.json`

## `PATCH /api/client/v1/provider/services/{service}`

Any actual change sets approval_status to pending and hides the service from customers until an administrator approves it again. Saving identical values changes nothing.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `service` | path | yes | integer |

### Request body and validation

See the request schema in `openapi.json`.

### Responses

#### HTTP 200: Service updated

Response schema: `#/components/schemas/ProviderServiceEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not a provider account, or provider not yet verified

Response schema: `see openapi.json`

#### HTTP 404: Service not found or owned by another provider

Response schema: `see openapi.json`

#### HTTP 422: Validation failed

Response schema: `see openapi.json`

## `PUT /api/client/v1/provider/services/{service}`

Any actual change sets approval_status to pending and hides the service from customers until an administrator approves it again. Saving identical values changes nothing.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `service` | path | yes | integer |

### Request body and validation

See the request schema in `openapi.json`.

### Responses

#### HTTP 200: Service updated

Response schema: `#/components/schemas/ProviderServiceEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not a provider account, or provider not yet verified

Response schema: `see openapi.json`

#### HTTP 404: Service not found or owned by another provider

Response schema: `see openapi.json`

#### HTTP 422: Validation failed

Response schema: `see openapi.json`

