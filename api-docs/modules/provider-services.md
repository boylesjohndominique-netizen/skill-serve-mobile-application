# Provider Services

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/provider/availability`

Get the authenticated provider's published weekly hours

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Weekly schedule and booking availability

Response schema: `#/components/schemas/ProviderAvailabilityEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified-email provider account required

Response schema: `see openapi.json`

#### HTTP 404: Provider profile not found

Response schema: `see openapi.json`

## `PUT /api/client/v1/provider/availability`

Sending `availability` replaces the whole schedule; an empty array clears it, which means the provider publishes no hours rather than being unavailable. A provider with no published hours can be booked at any time.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `is_accepting_bookings` | no | boolean |
| `availability` | no | array |

### Responses

#### HTTP 200: Updated schedule

Response schema: `#/components/schemas/ProviderAvailabilityEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified-email provider account required

Response schema: `see openapi.json`

#### HTTP 404: Provider profile not found

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `#/components/schemas/ApiEnvelope`

## `GET /api/client/v1/provider/badges`

Returns the badges this provider has earned and the active badges still available, so the app can show progress toward the rest.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Earned and available badges

Response schema: `#/components/schemas/ClientBadgeSetEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified-email provider account required

Response schema: `see openapi.json`

#### HTTP 404: Provider profile not found

Response schema: `see openapi.json`

## `GET /api/client/v1/provider/commission-preview`

SkillServe's commission is included in the price the provider advertises: the customer pays `amount`, the platform takes `commission_amount` out of it, and the provider receives `net_amount`. Call this while the provider is choosing a price so the split is visible before publishing.

Indicative only — the rate that binds a booking is snapshotted when the booking is made. `source` explains the rate: `tier` (a configured band matched), `gap` (the bands leave this amount uncovered, so nothing is charged) or `fallback` (no bands configured; the legacy flat rate applies).

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `amount` | query | yes | number |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Commission breakdown

```json
{
    "success": true,
    "message": "Commission preview calculated.",
    "data": {
        "amount": "200.00",
        "commission_rate": "10.00",
        "commission_amount": "20.00",
        "net_amount": "180.00",
        "currency": "PHP",
        "tier_name": "Standard",
        "source": "tier"
    },
    "errors": null,
    "meta": []
}
```

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, email-verified provider account required

Response schema: `see openapi.json`

#### HTTP 422: Missing or invalid amount

Response schema: `see openapi.json`

## `GET /api/client/v1/provider/portfolio`

List the authenticated provider's own work samples

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Portfolio items, newest first

Response schema: `#/components/schemas/ClientPortfolioListEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified-email provider account required

Response schema: `see openapi.json`

#### HTTP 404: Provider profile not found

Response schema: `see openapi.json`

## `POST /api/client/v1/provider/portfolio`

Add a work sample to the provider's own portfolio

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 201: Item added

Response schema: `#/components/schemas/ClientPortfolioEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified-email provider account required

Response schema: `see openapi.json`

#### HTTP 404: Provider profile not found

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `#/components/schemas/ApiEnvelope`

## `DELETE /api/client/v1/provider/portfolio/{item}`

Remove one of the provider's own work samples

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `item` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Item removed

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified-email provider account required

Response schema: `see openapi.json`

#### HTTP 404: Item not found, or it belongs to another provider

Response schema: `see openapi.json`

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

## `PATCH /api/client/v1/provider/profile`

Partial update. Verification status, featured flag and rating counters are not editable here — they are set by administrators or earned.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `business_name` | no | string, maxLength=255 |
| `bio` | no | string, maxLength=5000 |
| `specialization` | no | string, maxLength=255 |
| `experience_years` | no | integer, minimum=0, maximum=80 |
| `hourly_rate` | no | number, format=float |
| `location` | no | string, maxLength=255 |
| `website` | no | string, format=uri |
| `skills` | no | array |
| `certifications` | no | array |
| `languages` | no | array |

### Responses

#### HTTP 200: Updated profile

Response schema: `#/components/schemas/ProviderProfileEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified-email provider account required

Response schema: `see openapi.json`

#### HTTP 404: Provider profile not found

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `#/components/schemas/ApiEnvelope`

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

