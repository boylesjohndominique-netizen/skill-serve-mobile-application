# Reports

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/reports`

GET /api/reports — paginated, searchable, filterable report list.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `type` | query | no | string (`user`, `service`, `review`, `message`) |
| `status` | query | no | string (`pending`, `investigating`, `resolved`, `rejected`) |
| `reason` | query | no | string |
| `sort` | query | no | string (`created_at`, `updated_at`, `status`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated list of reports

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

## `GET /api/reports/{report}`

GET /api/reports/{report} — single report with its reported item.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `report` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Report details

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Not found

Response schema: `see openapi.json`

## `PATCH /api/reports/{report}/action`

PATCH /api/reports/{report}/action — take a moderation action on the reported item.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `report` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `action` | yes | string, one of: `warning`, `suspend`, `ban`, `hide`, `remove` |
| `reason` | no | string, maxLength=500 |
| `duration` | no | string, one of: `days`, `forever` |
| `days` | no | integer, minimum=1, maximum=3650 |
| `note` | no | string, maxLength=2000 |

Example request body:

```json
{
    "action": "suspend",
    "reason": "Repeated policy violations.",
    "note": "Suspended after investigation."
}
```

### Responses

#### HTTP 200: Moderation action taken

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Not found

Response schema: `see openapi.json`

#### HTTP 422: Terminal report / not applicable / validation error

Response schema: `see openapi.json`

## `PATCH /api/reports/{report}/investigate`

PATCH /api/reports/{report}/investigate — assign and start the investigation.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `report` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `note` | no | string, maxLength=2000 |

Example request body:

```json
{
    "note": "Reviewing the reported account now."
}
```

### Responses

#### HTTP 200: Report investigation started

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Not found

Response schema: `see openapi.json`

#### HTTP 422: Terminal report / validation error

Response schema: `see openapi.json`

## `PATCH /api/reports/{report}/notes`

PATCH /api/reports/{report}/notes — append an investigation note.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `report` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `note` | yes | string, maxLength=2000 |

Example request body:

```json
{
    "note": "Evidence reviewed \u2014 no violation found."
}
```

### Responses

#### HTTP 200: Investigation note added

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Not found

Response schema: `see openapi.json`

#### HTTP 422: Terminal report / validation error

Response schema: `see openapi.json`

## `PATCH /api/reports/{report}/reject`

PATCH /api/reports/{report}/reject — mark a report as rejected (no violation).

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `report` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `reason` | yes | string, maxLength=1000 |

Example request body:

```json
{
    "reason": "No violation was found during review."
}
```

### Responses

#### HTTP 200: Report rejected

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Not found

Response schema: `see openapi.json`

#### HTTP 422: Terminal report / validation error

Response schema: `see openapi.json`

## `PATCH /api/reports/{report}/resolve`

PATCH /api/reports/{report}/resolve — mark a report as resolved.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `report` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `resolution_note` | yes | string, maxLength=2000 |

Example request body:

```json
{
    "resolution_note": "Account suspended and report closed."
}
```

### Responses

#### HTTP 200: Report resolved

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Not found

Response schema: `see openapi.json`

#### HTTP 422: Terminal report / validation error

Response schema: `see openapi.json`

