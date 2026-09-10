# Roles

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/roles`

GET /api/roles — paginated, searchable list of roles.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `sort` | query | no | string (`name`, `created_at`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated list of roles

```json
{
    "success": true,
    "message": "Request successful.",
    "data": [
        {
            "id": 3,
            "name": "reports-manager",
            "description": "Manages operational reports.",
            "guard_name": "web",
            "permissions": [
                "view reports"
            ],
            "created_at": "2026-08-07T08:00:00+00:00"
        }
    ],
    "errors": null,
    "meta": {
        "pagination": {
            "total": 1,
            "per_page": 15,
            "current_page": 1,
            "last_page": 1,
            "from": 1,
            "to": 1
        }
    }
}
```

#### HTTP 401: Unauthenticated / expired token

```json
{
    "success": false,
    "message": "Unauthenticated.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 403: Missing the manage administrators permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `POST /api/roles`

POST /api/roles — create a new role.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `name` | yes | string |
| `description` | no | string |
| `permissions` | no | array |

Example request body:

```json
{
    "name": "reports-manager",
    "description": "Manages operational reports."
}
```

### Responses

#### HTTP 201: Role created

```json
{
    "success": true,
    "message": "Role created.",
    "data": {
        "id": 3,
        "name": "reports-manager",
        "description": "Manages operational reports.",
        "guard_name": "web",
        "permissions": [],
        "created_at": "2026-08-07T08:00:00+00:00"
    },
    "errors": null,
    "meta": []
}
```

#### HTTP 401: Unauthenticated / expired token

```json
{
    "success": false,
    "message": "Unauthenticated.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 403: Missing the manage administrators permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "name": [
            "The name field is required."
        ]
    },
    "meta": []
}
```

## `DELETE /api/roles/{role}`

DELETE /api/roles/{role} — delete a role (system role protected).

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `role` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Role deleted

```json
{
    "success": true,
    "message": "Role deleted.",
    "data": null,
    "errors": null,
    "meta": []
}
```

#### HTTP 401: Unauthenticated / expired token

```json
{
    "success": false,
    "message": "Unauthenticated.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 403: Missing the manage administrators permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Role not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: System default role cannot be deleted

```json
{
    "success": false,
    "message": "The system default role cannot be deleted.",
    "data": [],
    "errors": {
        "role": [
            "The system default role cannot be deleted."
        ]
    },
    "meta": []
}
```

## `GET /api/roles/{role}`

GET /api/roles/{role} — a single role with its permissions.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `role` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Role details

```json
{
    "success": true,
    "message": "Request successful.",
    "data": {
        "id": 3,
        "name": "reports-manager",
        "description": "Manages operational reports.",
        "guard_name": "web",
        "permissions": [
            "view reports"
        ],
        "created_at": "2026-08-07T08:00:00+00:00"
    },
    "errors": null,
    "meta": []
}
```

#### HTTP 401: Unauthenticated / expired token

```json
{
    "success": false,
    "message": "Unauthenticated.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 403: Missing the manage administrators permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Role not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/roles/{role}`

PUT/PATCH /api/roles/{role} — update name/description.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `role` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `name` | no | string |
| `description` | no | string |

Example request body:

```json
{
    "name": "reports-manager",
    "description": "Manages operational and executive reports."
}
```

### Responses

#### HTTP 200: Role updated

```json
{
    "success": true,
    "message": "Role updated.",
    "data": {
        "id": 3,
        "name": "reports-manager",
        "description": "Manages operational and executive reports.",
        "guard_name": "web",
        "permissions": [
            "view reports"
        ],
        "created_at": "2026-08-07T08:00:00+00:00"
    },
    "errors": null,
    "meta": []
}
```

#### HTTP 401: Unauthenticated / expired token

```json
{
    "success": false,
    "message": "Unauthenticated.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 403: Missing the manage administrators permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Role not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "name": [
            "A role with this name already exists."
        ]
    },
    "meta": []
}
```

## `PUT /api/roles/{role}`

PUT/PATCH /api/roles/{role} — update name/description.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `role` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `name` | no | string |
| `description` | no | string |

Example request body:

```json
{
    "name": "reports-manager",
    "description": "Manages operational and executive reports."
}
```

### Responses

#### HTTP 200: Role updated

```json
{
    "success": true,
    "message": "Role updated.",
    "data": {
        "id": 3,
        "name": "reports-manager",
        "description": "Manages operational and executive reports.",
        "guard_name": "web",
        "permissions": [
            "view reports"
        ],
        "created_at": "2026-08-07T08:00:00+00:00"
    },
    "errors": null,
    "meta": []
}
```

#### HTTP 401: Unauthenticated / expired token

```json
{
    "success": false,
    "message": "Unauthenticated.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 403: Missing the manage administrators permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Role not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "name": [
            "A role with this name already exists."
        ]
    },
    "meta": []
}
```

## `PUT /api/roles/{role}/permissions`

PUT /api/roles/{role}/permissions — sync the permission matrix for a role.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `role` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `permissions` | yes | array |

Example request body:

```json
{
    "permissions": [
        "view reports",
        "manage bookings"
    ]
}
```

### Responses

#### HTTP 200: Role permissions synced

```json
{
    "success": true,
    "message": "Role permissions updated.",
    "data": {
        "id": 3,
        "name": "reports-manager",
        "description": "Manages operational reports.",
        "guard_name": "web",
        "permissions": [
            "view reports",
            "manage bookings"
        ],
        "created_at": "2026-08-07T08:00:00+00:00"
    },
    "errors": null,
    "meta": []
}
```

#### HTTP 401: Unauthenticated / expired token

```json
{
    "success": false,
    "message": "Unauthenticated.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 403: Missing the manage administrators permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Role not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error / super administrator permissions immutable

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "permissions.0": [
            "One or more selected permissions do not exist."
        ]
    },
    "meta": []
}
```

