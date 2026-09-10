# Users

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/users`

GET /api/users — paginated, searchable, filterable list of platform users.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `user_type` | query | no | string (`customer`) |
| `status` | query | no | string (`active`, `suspended`, `banned`) |
| `verification` | query | no | string (`verified`, `unverified`) |
| `sort` | query | no | string (`name`, `created_at`, `last_login_at`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated list of users

```json
{
    "success": true,
    "message": "Users retrieved.",
    "data": [
        {
            "id": 3,
            "name": "Alice Customer",
            "email": "alice@skillserve.test",
            "roles": [],
            "permissions": [],
            "first_name": "Alice",
            "last_name": "Customer",
            "user_type": "customer",
            "phone": "+1 555 0100",
            "status": "active",
            "verification": "verified",
            "last_login_at": null,
            "created_by": null,
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

#### HTTP 403: Missing the manage users permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `DELETE /api/users/{user}`

DELETE /api/users/{user} — soft-delete a user account.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `user` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: User deleted (soft delete)

```json
{
    "success": true,
    "message": "User deleted.",
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

#### HTTP 403: Missing the manage users permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: User not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Deletion guard violated (e.g. deleting your own account)

```json
{
    "success": false,
    "message": "You cannot delete your own account.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `GET /api/users/{user}`

GET /api/users/{user} — detailed user profile.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `user` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: User profile details

```json
{
    "success": true,
    "message": "Request successful.",
    "data": {
        "id": 3,
        "name": "Alice Customer",
        "email": "alice@skillserve.test",
        "user_type": "customer",
        "phone": "+1 555 0100",
        "address": "123 Main St",
        "birthday": "1995-04-12",
        "status": "active",
        "verification": "verified",
        "summary": {
            "services_count": 0,
            "bookings_count": 0,
            "ratings_count": 0,
            "reviews_count": 0,
            "recent_activity": []
        }
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

#### HTTP 403: Missing the manage users permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: User not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/users/{user}`

PUT/PATCH /api/users/{user} — update a user's profile.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `user` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `first_name` | no | string |
| `last_name` | no | string |
| `email` | no | string, format=email |
| `phone` | no | string |
| `address` | no | string |
| `birthday` | no | string, format=date |
| `user_type` | no | string, one of: `customer` |

Example request body:

```json
{
    "first_name": "Alice",
    "last_name": "Customer",
    "email": "alice@skillserve.test",
    "phone": "+1 555 0100",
    "address": "123 Main St",
    "birthday": "1995-04-12",
    "user_type": "customer"
}
```

### Responses

#### HTTP 200: User updated

```json
{
    "success": true,
    "message": "User updated.",
    "data": {
        "id": 3,
        "name": "Alice Customer",
        "email": "alice@skillserve.test",
        "roles": [],
        "permissions": [],
        "first_name": "Alice",
        "last_name": "Customer",
        "user_type": "customer",
        "phone": "+1 555 0100",
        "status": "active",
        "verification": "verified",
        "last_login_at": null,
        "created_by": null,
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

#### HTTP 403: Missing the manage users permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: User not found

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
            "A user with this email already exists."
        ]
    },
    "meta": []
}
```

## `PUT /api/users/{user}`

PUT/PATCH /api/users/{user} — update a user's profile.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `user` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `first_name` | no | string |
| `last_name` | no | string |
| `email` | no | string, format=email |
| `phone` | no | string |
| `address` | no | string |
| `birthday` | no | string, format=date |
| `user_type` | no | string, one of: `customer` |

Example request body:

```json
{
    "first_name": "Alice",
    "last_name": "Customer",
    "email": "alice@skillserve.test",
    "phone": "+1 555 0100",
    "address": "123 Main St",
    "birthday": "1995-04-12",
    "user_type": "customer"
}
```

### Responses

#### HTTP 200: User updated

```json
{
    "success": true,
    "message": "User updated.",
    "data": {
        "id": 3,
        "name": "Alice Customer",
        "email": "alice@skillserve.test",
        "roles": [],
        "permissions": [],
        "first_name": "Alice",
        "last_name": "Customer",
        "user_type": "customer",
        "phone": "+1 555 0100",
        "status": "active",
        "verification": "verified",
        "last_login_at": null,
        "created_by": null,
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

#### HTTP 403: Missing the manage users permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: User not found

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
            "A user with this email already exists."
        ]
    },
    "meta": []
}
```

## `PATCH /api/users/{user}/activate`

PATCH /api/users/{user}/activate — restore a suspended user.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `user` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: User activated

```json
{
    "success": true,
    "message": "User activated.",
    "data": {
        "id": 3,
        "name": "Alice Customer",
        "email": "alice@skillserve.test",
        "roles": [],
        "permissions": [],
        "first_name": "Alice",
        "last_name": "Customer",
        "user_type": "customer",
        "phone": "+1 555 0100",
        "status": "active",
        "verification": "verified",
        "last_login_at": null,
        "created_by": null,
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

#### HTTP 403: Missing the manage users permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: User not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Account state guard (e.g. banned accounts are terminal)

```json
{
    "success": false,
    "message": "A banned account cannot be activated.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/users/{user}/ban`

PATCH /api/users/{user}/ban — ban a user for a number of days or forever.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `user` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `reason` | yes | string, maxLength=500 |
| `duration` | yes | string, one of: `days`, `forever` |
| `days` | no | integer, minimum=1, maximum=3650 |

Example request body:

```json
{
    "reason": "Repeated policy violations.",
    "duration": "days",
    "days": 30
}
```

### Responses

#### HTTP 200: User banned

```json
{
    "success": true,
    "message": "User banned.",
    "data": {
        "id": 3,
        "name": "Alice Customer",
        "email": "alice@skillserve.test",
        "roles": [],
        "permissions": [],
        "first_name": "Alice",
        "last_name": "Customer",
        "user_type": "customer",
        "phone": "+1 555 0100",
        "status": "banned",
        "verification": "verified",
        "last_login_at": null,
        "created_by": null,
        "banned_until": "2026-09-06T08:00:00+00:00",
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

#### HTTP 403: Missing the manage users permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: User not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error / account state guard

```json
{
    "success": false,
    "message": "The account is already banned.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `GET /api/users/{user}/moderation-history`

GET /api/users/{user}/moderation-history — full ban/unban audit trail.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `user` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Moderation history (newest first)

```json
{
    "success": true,
    "message": "Moderation history retrieved.",
    "data": [
        {
            "id": 42,
            "event": "user_banned",
            "logged_at": "2026-08-07T08:00:00+00:00",
            "actor": {
                "id": 1,
                "name": "System Administrator"
            },
            "properties": {
                "reason": "Repeated policy violations."
            }
        },
        {
            "id": 41,
            "event": "user_unbanned",
            "logged_at": "2026-08-01T09:00:00+00:00",
            "actor": null,
            "properties": {
                "reason": "Temporary ban expired."
            }
        }
    ],
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

#### HTTP 403: Missing the manage users permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: User not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/users/{user}/suspend`

PATCH /api/users/{user}/suspend — temporarily suspend a user.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `user` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `reason` | yes | string, maxLength=500 |

Example request body:

```json
{
    "reason": "Suspected fraudulent activity."
}
```

### Responses

#### HTTP 200: User suspended

```json
{
    "success": true,
    "message": "User suspended.",
    "data": {
        "id": 3,
        "name": "Alice Customer",
        "email": "alice@skillserve.test",
        "roles": [],
        "permissions": [],
        "first_name": "Alice",
        "last_name": "Customer",
        "user_type": "customer",
        "phone": "+1 555 0100",
        "status": "suspended",
        "verification": "verified",
        "last_login_at": null,
        "created_by": null,
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

#### HTTP 403: Missing the manage users permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: User not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error / account state guard

```json
{
    "success": false,
    "message": "The account is already suspended.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/users/{user}/unban`

PATCH /api/users/{user}/unban — lift a ban (temporary or permanent).

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `user` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `reason` | no | string, maxLength=500 |

Example request body:

```json
{
    "reason": "Ban lifted after review."
}
```

### Responses

#### HTTP 200: User unbanned

```json
{
    "success": true,
    "message": "User unbanned.",
    "data": {
        "id": 3,
        "name": "Alice Customer",
        "email": "alice@skillserve.test",
        "roles": [],
        "permissions": [],
        "first_name": "Alice",
        "last_name": "Customer",
        "user_type": "customer",
        "phone": "+1 555 0100",
        "status": "active",
        "verification": "verified",
        "last_login_at": null,
        "created_by": null,
        "banned_until": null,
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

#### HTTP 403: Missing the manage users permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: User not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Account is not currently banned

```json
{
    "success": false,
    "message": "The account is not currently banned.",
    "data": [],
    "errors": null,
    "meta": []
}
```

