# Authentication

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `POST /api/auth/change-password`

POST /api/auth/change-password — verify the current password and store a new one.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `current_password` | yes | string, format=password |
| `password` | yes | string, format=password, minLength=8 |
| `password_confirmation` | yes | string, format=password |

Example request body:

```json
{
    "current_password": "SkillServe#2026",
    "password": "SkillServe#2027",
    "password_confirmation": "SkillServe#2027"
}
```

### Responses

#### HTTP 200: Password changed successfully

```json
{
    "success": true,
    "message": "Password changed successfully.",
    "data": null,
    "errors": null,
    "meta": null
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

#### HTTP 422: Validation error / wrong current password

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "current_password": [
            "The current password is incorrect."
        ]
    },
    "meta": []
}
```

## `POST /api/auth/login`

POST /api/auth/login — validate credentials and issue a Sanctum token.

**Authentication:** Public

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `email` | yes | string, format=email |
| `password` | yes | string, format=password |

Example request body:

```json
{
    "email": "admin@skillserve.test",
    "password": "SkillServe#2026"
}
```

### Responses

#### HTTP 200: Logged in successfully

```json
{
    "success": true,
    "message": "Logged in successfully.",
    "data": {
        "token": "1|a1b2c3d4e5f6g7h8i9j0",
        "token_type": "Bearer",
        "expires_at": "2026-08-08T15:00:00+00:00",
        "user": {
            "id": 1,
            "name": "System Administrator",
            "email": "admin@skillserve.test",
            "roles": [
                "super-admin"
            ],
            "permissions": [
                "manage administrators"
            ],
            "created_at": "2026-08-07T15:00:00+00:00"
        }
    },
    "errors": null,
    "meta": null
}
```

#### HTTP 401: Invalid credentials

```json
{
    "success": false,
    "message": "Invalid email or password.",
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
            "The email field must be a valid email address."
        ]
    },
    "meta": []
}
```

#### HTTP 429: Too many login attempts

```json
{
    "success": false,
    "message": "Too many login attempts. Please try again later.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `POST /api/auth/logout`

POST /api/auth/logout — revoke the current session token.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Logged out successfully

```json
{
    "success": true,
    "message": "Logged out successfully.",
    "data": null,
    "errors": null,
    "meta": null
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

## `GET /api/auth/me`

GET /api/auth/me — the authenticated administrator (roles + permissions).

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Authenticated user

```json
{
    "success": true,
    "message": "Authenticated user.",
    "data": {
        "id": 1,
        "name": "System Administrator",
        "email": "admin@skillserve.test",
        "roles": [
            "super-admin"
        ],
        "permissions": [
            "manage administrators"
        ],
        "created_at": "2026-08-07T15:00:00+00:00"
    },
    "errors": null,
    "meta": null
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

