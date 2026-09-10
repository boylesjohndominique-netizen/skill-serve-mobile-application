# Permissions

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/permissions`

GET /api/permissions — every permission grouped by module.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Permission matrix

```json
{
    "success": true,
    "message": "Request successful.",
    "data": [
        {
            "module": "Administrators",
            "permissions": [
                {
                    "id": 1,
                    "name": "manage administrators",
                    "module": "Administrators",
                    "guard_name": "web"
                }
            ]
        },
        {
            "module": "Reports",
            "permissions": [
                {
                    "id": 5,
                    "name": "view reports",
                    "module": "Reports",
                    "guard_name": "web"
                }
            ]
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

