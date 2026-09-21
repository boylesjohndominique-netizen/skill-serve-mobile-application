# Client Reports

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/reports`

List the reports the signed-in account has filed

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `status` | query | no | string (`pending`, `investigating`, `resolved`, `rejected`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Reports filed by the account

Response schema: `#/components/schemas/ClientReportListEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active customer or provider account required

Response schema: `see openapi.json`

#### HTTP 422: Invalid filter

Response schema: `see openapi.json`

## `POST /api/client/v1/reports`

Send exactly one subject. `booking_id` reports the other party on a booking the caller took part in; `review_id` reports a published review (not the caller's own); `message_id` reports a message the caller received. Moderators review every report from the admin console. One open report per subject per reporter.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `booking_id` | no | integer |
| `review_id` | no | integer |
| `message_id` | no | integer |
| `reason` | yes | string, one of: `service_quality`, `no_show`, `safety_concern`, `payment_dispute`, `misleading_information`, `harassment`, `inappropriate_content`, `spam`, `other` |
| `description` | yes | string, minLength=10, maxLength=2000 |

### Responses

#### HTTP 201: Report filed

Response schema: `#/components/schemas/ClientReportEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Active customer or provider account required

Response schema: `see openapi.json`

#### HTTP 404: Subject not found, or not one the caller may report

Response schema: `see openapi.json`

#### HTTP 409: An earlier report about this subject is still open

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

## `GET /api/client/v1/reports/{report}`

Get a report the signed-in account filed

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `report` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Report details

Response schema: `#/components/schemas/ClientReportEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Not filed by the caller

Response schema: `see openapi.json`

#### HTTP 404: Report not found

Response schema: `see openapi.json`

