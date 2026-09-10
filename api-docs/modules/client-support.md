# Client Support

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/support/tickets`

List the authenticated customer support tickets

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `status` | query | no | string (`open`, `in_progress`, `resolved`) |
| `per_page` | query | no | integer |
| `page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated customer tickets

Response schema: `#/components/schemas/ClientSupportTicketListEnvelope`

#### HTTP 403: Active, verified client access required

Response schema: `see openapi.json`

#### HTTP 422: Invalid filter

Response schema: `see openapi.json`

## `POST /api/client/v1/support/tickets`

Create a support ticket for the authenticated customer

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `subject` | yes | string, maxLength=160 |
| `description` | yes | string, maxLength=10000 |
| `category` | no | string, maxLength=40 |

### Responses

#### HTTP 201: Support ticket created

Response schema: `#/components/schemas/ClientSupportTicketEnvelope`

#### HTTP 403: Active, verified client access required

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

## `GET /api/client/v1/support/tickets/{ticket}`

Get an owned customer support ticket

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `ticket` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Support ticket details

Response schema: `#/components/schemas/ClientSupportTicketEnvelope`

#### HTTP 403: Active, verified client access required

Response schema: `see openapi.json`

#### HTTP 404: Ticket not found

Response schema: `see openapi.json`

## `POST /api/client/v1/support/tickets/{ticket}/replies`

Reply to an owned customer support ticket

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `ticket` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `body` | yes | string, maxLength=5000 |

### Responses

#### HTTP 200: Reply added

Response schema: `#/components/schemas/ClientSupportTicketEnvelope`

#### HTTP 403: Active, verified client access required

Response schema: `see openapi.json`

#### HTTP 404: Ticket not found

Response schema: `see openapi.json`

#### HTTP 422: Validation error or resolved ticket

Response schema: `see openapi.json`

