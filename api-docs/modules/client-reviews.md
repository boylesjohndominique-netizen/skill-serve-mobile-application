# Client Reviews

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/reviews`

List the authenticated customer reviews

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Customer reviews

Response schema: `#/components/schemas/ClientReviewListEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified client access required

Response schema: `see openapi.json`

#### HTTP 422: Invalid pagination

Response schema: `see openapi.json`

## `POST /api/client/v1/reviews`

Review a completed owned booking

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `booking_id` | yes | integer |
| `rating` | yes | integer, minimum=1, maximum=5 |
| `comment` | no | string, maxLength=2000 |

### Responses

#### HTTP 201: Review created

Response schema: `#/components/schemas/ClientReviewEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active, verified client access required

Response schema: `see openapi.json`

#### HTTP 409: Booking already reviewed

Response schema: `see openapi.json`

#### HTTP 422: Booking is not completed or validation failed

Response schema: `see openapi.json`

## `PATCH /api/client/v1/reviews/{review}`

Update an owned review

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `review` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `rating` | no | integer, minimum=1, maximum=5 |
| `comment` | no | string, maxLength=2000 |

### Responses

#### HTTP 200: Review updated

Response schema: `#/components/schemas/ClientReviewEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not owned by the customer

Response schema: `see openapi.json`

#### HTTP 404: Review not found

Response schema: `see openapi.json`

#### HTTP 422: Booking is not completed

Response schema: `see openapi.json`

## `PUT /api/client/v1/reviews/{review}`

Update an owned review

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `review` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `rating` | no | integer, minimum=1, maximum=5 |
| `comment` | no | string, maxLength=2000 |

### Responses

#### HTTP 200: Review updated

Response schema: `#/components/schemas/ClientReviewEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not owned by the customer

Response schema: `see openapi.json`

#### HTTP 404: Review not found

Response schema: `see openapi.json`

#### HTTP 422: Booking is not completed

Response schema: `see openapi.json`

