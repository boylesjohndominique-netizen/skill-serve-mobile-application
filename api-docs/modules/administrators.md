# Administrators

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/administrators`

GET /api/administrators — paginated, searchable, filterable list.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `status` | query | no | string (`active`, `inactive`) |
| `role` | query | no | string |
| `sort` | query | no | string (`name`, `created_at`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated list of administrators

```json
{
    "success": true,
    "message": "Request successful.",
    "data": [
        {
            "id": 2,
            "first_name": "Jane",
            "last_name": "Doe",
            "name": "Jane Doe",
            "email": "jane.doe@skillserve.test",
            "status": "active",
            "roles": [
                "admin"
            ],
            "permissions": [
                "view reports"
            ],
            "last_login_at": "2026-08-07T09:30:00+00:00",
            "created_by": {
                "id": 1,
                "name": "System Administrator"
            },
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

## `POST /api/administrators`

POST /api/administrators — create a new administrator account.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `first_name` | yes | string |
| `last_name` | yes | string |
| `email` | yes | string, format=email |
| `password` | yes | string, format=password, minLength=8 |
| `password_confirmation` | no | string, format=password |
| `role` | yes | string |

Example request body:

```json
{
    "first_name": "Jane",
    "last_name": "Doe",
    "email": "jane.doe@skillserve.test",
    "password": "Secret#2026",
    "password_confirmation": "Secret#2026",
    "role": "admin"
}
```

### Responses

#### HTTP 201: Administrator created

```json
{
    "success": true,
    "message": "Administrator created.",
    "data": {
        "id": 2,
        "first_name": "Jane",
        "last_name": "Doe",
        "name": "Jane Doe",
        "email": "jane.doe@skillserve.test",
        "status": "active",
        "roles": [
            "admin"
        ],
        "permissions": [],
        "last_login_at": null,
        "created_by": {
            "id": 1,
            "name": "System Administrator"
        },
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
        "first_name": [
            "The first name field is required."
        ],
        "last_name": [
            "The last name field is required."
        ],
        "email": [
            "The email field is required."
        ],
        "password": [
            "The password field is required."
        ],
        "role": [
            "The role field is required."
        ]
    },
    "meta": []
}
```

## `GET /api/administrators/{administrator}`

GET /api/administrators/{administrator} — a single administrator.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `administrator` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Administrator details

```json
{
    "success": true,
    "message": "Request successful.",
    "data": {
        "id": 2,
        "first_name": "Jane",
        "last_name": "Doe",
        "name": "Jane Doe",
        "email": "jane.doe@skillserve.test",
        "status": "active",
        "roles": [
            "admin"
        ],
        "permissions": [
            "view reports"
        ],
        "last_login_at": "2026-08-07T09:30:00+00:00",
        "created_by": {
            "id": 1,
            "name": "System Administrator"
        },
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

#### HTTP 404: Administrator not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/administrators/{administrator}`

PUT/PATCH /api/administrators/{administrator} — update name, email, role or status.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `administrator` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `first_name` | no | string |
| `last_name` | no | string |
| `email` | no | string, format=email |
| `role` | no | string |
| `status` | no | string, one of: `active`, `inactive` |

Example request body:

```json
{
    "first_name": "Jane",
    "last_name": "Doe",
    "email": "jane.doe@skillserve.test",
    "role": "admin",
    "status": "active"
}
```

### Responses

#### HTTP 200: Administrator updated

```json
{
    "success": true,
    "message": "Administrator updated.",
    "data": {
        "id": 2,
        "first_name": "Jane",
        "last_name": "Doe",
        "name": "Jane Doe",
        "email": "jane.doe@skillserve.test",
        "status": "active",
        "roles": [
            "admin"
        ],
        "permissions": [
            "view reports"
        ],
        "last_login_at": "2026-08-07T09:30:00+00:00",
        "created_by": {
            "id": 1,
            "name": "System Administrator"
        },
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

#### HTTP 404: Administrator not found

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
        "email": [
            "An administrator with this email already exists."
        ]
    },
    "meta": []
}
```

## `PUT /api/administrators/{administrator}`

PUT/PATCH /api/administrators/{administrator} — update name, email, role or status.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `administrator` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `first_name` | no | string |
| `last_name` | no | string |
| `email` | no | string, format=email |
| `role` | no | string |
| `status` | no | string, one of: `active`, `inactive` |

Example request body:

```json
{
    "first_name": "Jane",
    "last_name": "Doe",
    "email": "jane.doe@skillserve.test",
    "role": "admin",
    "status": "active"
}
```

### Responses

#### HTTP 200: Administrator updated

```json
{
    "success": true,
    "message": "Administrator updated.",
    "data": {
        "id": 2,
        "first_name": "Jane",
        "last_name": "Doe",
        "name": "Jane Doe",
        "email": "jane.doe@skillserve.test",
        "status": "active",
        "roles": [
            "admin"
        ],
        "permissions": [
            "view reports"
        ],
        "last_login_at": "2026-08-07T09:30:00+00:00",
        "created_by": {
            "id": 1,
            "name": "System Administrator"
        },
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

#### HTTP 404: Administrator not found

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
        "email": [
            "An administrator with this email already exists."
        ]
    },
    "meta": []
}
```

## `PATCH /api/administrators/{administrator}/password`

Sets a new password for the account and revokes all existing sessions. A super administrator's password can only be changed by that super administrator themselves; regular administrators use the self-service change-password flow for their own account.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `administrator` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `password` | yes | string, format=password, minLength=8 |
| `password_confirmation` | yes | string, format=password |

Example request body:

```json
{
    "password": "NewSecret#2026",
    "password_confirmation": "NewSecret#2026"
}
```

### Responses

#### HTTP 200: Password reset — existing sessions revoked

```json
{
    "success": true,
    "message": "Administrator password updated.",
    "data": {
        "id": 2,
        "first_name": "Jane",
        "last_name": "Doe",
        "name": "Jane Doe",
        "email": "jane.doe@skillserve.test",
        "status": "active",
        "roles": [
            "admin"
        ],
        "permissions": [
            "view reports"
        ],
        "last_login_at": "2026-08-07T09:30:00+00:00",
        "created_by": {
            "id": 1,
            "name": "System Administrator"
        },
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

#### HTTP 403: Missing the manage administrators permission, or resetting a super administrator without being one

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Administrator not found

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
        "password": [
            "The new password must be at least 8 characters."
        ]
    },
    "meta": []
}
```

## `PATCH /api/administrators/{administrator}/status`

PATCH /api/administrators/{administrator}/status — activate or deactivate.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `administrator` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `status` | yes | string, one of: `active`, `inactive` |

Example request body:

```json
{
    "status": "inactive"
}
```

### Responses

#### HTTP 200: Administrator status updated

```json
{
    "success": true,
    "message": "Administrator status updated.",
    "data": {
        "id": 2,
        "first_name": "Jane",
        "last_name": "Doe",
        "name": "Jane Doe",
        "email": "jane.doe@skillserve.test",
        "status": "inactive",
        "roles": [
            "admin"
        ],
        "permissions": [
            "view reports"
        ],
        "last_login_at": "2026-08-07T09:30:00+00:00",
        "created_by": {
            "id": 1,
            "name": "System Administrator"
        },
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

#### HTTP 404: Administrator not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error / guard rule violated

```json
{
    "success": false,
    "message": "You cannot deactivate your own account.",
    "data": [],
    "errors": {
        "status": [
            "You cannot deactivate your own account."
        ]
    },
    "meta": []
}
```

