# Support

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/support/tickets`

List support tickets

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `status` | query | no | string (`open`, `in_progress`, `resolved`) |
| `priority` | query | no | string (`low`, `normal`, `high`, `urgent`) |
| `category` | query | no | string |
| `assigned_to` | query | no | integer |
| `sort` | query | no | string (`created_at`, `updated_at`, `priority`, `status`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |
| `page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated support tickets

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

## `GET /api/support/tickets/assignees`

List active administrator assignees

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Active assignees

Response schema: `#/components/schemas/ApiEnvelope`

## `GET /api/support/tickets/{ticket}`

Get support ticket details

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `ticket` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Support ticket details

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 404: Support ticket not found

Response schema: `see openapi.json`

## `PATCH /api/support/tickets/{ticket}/assign`

Assign or unassign a support ticket

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `ticket` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `assigned_to` | no | integer |

Example request body:

```json
{
    "assigned_to": 2
}
```

### Responses

#### HTTP 200: Ticket assignment updated

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Invalid assignee

Response schema: `see openapi.json`

## `PATCH /api/support/tickets/{ticket}/resolve`

Resolve a support ticket

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `ticket` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `resolution_note` | yes | string, maxLength=2000 |

Example request body:

```json
{
    "resolution_note": "The issue was resolved."
}
```

### Responses

#### HTTP 200: Ticket resolved

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Already resolved or validation error

Response schema: `see openapi.json`

## `POST /api/support/tickets/{ticket}/responses`

Add a support ticket response

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `ticket` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `body` | yes | string, maxLength=5000 |

Example request body:

```json
{
    "body": "We have reviewed your request."
}
```

### Responses

#### HTTP 200: Response added

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 422: Resolved ticket or validation error

Response schema: `see openapi.json`

