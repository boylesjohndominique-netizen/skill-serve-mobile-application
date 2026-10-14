# Permissions

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/permissions`

One group per area of the admin web (config/permission-areas.php). `view_permissions` is the read-only level; `permissions` is everything full control grants, view first. Permissions in no area are listed under key `other`.

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
            "key": "settings",
            "module": "System settings",
            "description": "Platform rules, policies and appearance.",
            "view_permissions": [
                "view settings"
            ],
            "permissions": [
                {
                    "id": 90,
                    "name": "view settings",
                    "module": "Settings",
                    "guard_name": "web"
                },
                {
                    "id": 91,
                    "name": "manage settings",
                    "module": "Settings",
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

