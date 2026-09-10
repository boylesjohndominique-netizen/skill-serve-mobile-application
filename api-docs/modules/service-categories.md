# Service Categories

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/service-categories`

GET /api/service-categories — paginated, searchable, filterable list.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `status` | query | no | string (`enabled`, `disabled`) |
| `sort` | query | no | string (`name`, `created_at`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated list of service categories

```json
{
    "success": true,
    "message": "Service categories retrieved.",
    "data": [
        {
            "id": 1,
            "name": "Home Maintenance",
            "description": "Plumbing, electrical and painting services.",
            "status": "enabled",
            "subcategories_count": 3,
            "created_by": {
                "id": 1,
                "name": "System Administrator"
            },
            "created_at": "2026-08-12T08:00:00+00:00",
            "updated_at": "2026-08-12T08:00:00+00:00"
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

#### HTTP 403: Missing the manage service categories permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `POST /api/service-categories`

POST /api/service-categories — create a new service category.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `name` | yes | string, maxLength=255 |
| `description` | no | string, maxLength=1000 |
| `status` | no | string, one of: `enabled`, `disabled` |

Example request body:

```json
{
    "name": "Home Maintenance",
    "description": "Plumbing, electrical and painting services."
}
```

### Responses

#### HTTP 201: Service category created

```json
{
    "success": true,
    "message": "Service category created.",
    "data": {
        "id": 1,
        "name": "Home Maintenance",
        "description": "Plumbing, electrical and painting services.",
        "status": "enabled",
        "subcategories_count": 0,
        "created_by": {
            "id": 1,
            "name": "System Administrator"
        },
        "created_at": "2026-08-12T08:00:00+00:00",
        "updated_at": "2026-08-12T08:00:00+00:00"
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

#### HTTP 403: Missing the manage service categories permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error (e.g. duplicate name)

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "name": [
            "A service category with this name already exists."
        ]
    },
    "meta": []
}
```

## `DELETE /api/service-categories/{serviceCategory}`

Soft-deletes the category. A category that still has subcategories cannot be deleted — remove its subcategories first.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `serviceCategory` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Service category deleted (soft delete)

```json
{
    "success": true,
    "message": "Service category deleted.",
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

#### HTTP 403: Missing the manage service categories permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Service category not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Deletion guard violated (category still has subcategories)

```json
{
    "success": false,
    "message": "This category still has subcategories. Delete its subcategories first.",
    "data": [],
    "errors": {
        "subcategories": [
            "This category still has subcategories. Delete its subcategories first."
        ]
    },
    "meta": []
}
```

## `GET /api/service-categories/{serviceCategory}`

GET /api/service-categories/{serviceCategory} — a category with its subcategories.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `serviceCategory` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Service category details with nested subcategories

```json
{
    "success": true,
    "message": "Request successful.",
    "data": {
        "id": 1,
        "name": "Home Maintenance",
        "description": "Plumbing, electrical and painting services.",
        "status": "enabled",
        "subcategories": [
            {
                "id": 1,
                "category_id": 1,
                "name": "Plumbing",
                "description": null,
                "status": "enabled",
                "created_at": "2026-08-12T08:00:00+00:00",
                "updated_at": "2026-08-12T08:00:00+00:00"
            }
        ],
        "created_by": {
            "id": 1,
            "name": "System Administrator"
        },
        "created_at": "2026-08-12T08:00:00+00:00",
        "updated_at": "2026-08-12T08:00:00+00:00"
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

#### HTTP 403: Missing the manage service categories permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Service category not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/service-categories/{serviceCategory}`

PUT/PATCH /api/service-categories/{serviceCategory} — update name/description.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `serviceCategory` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `name` | no | string, maxLength=255 |
| `description` | no | string, maxLength=1000 |
| `status` | no | string, one of: `enabled`, `disabled` |

Example request body:

```json
{
    "name": "Home Maintenance & Repair",
    "description": "Plumbing, electrical, painting and repair services."
}
```

### Responses

#### HTTP 200: Service category updated

```json
{
    "success": true,
    "message": "Service category updated.",
    "data": {
        "id": 1,
        "name": "Home Maintenance & Repair",
        "description": "Plumbing, electrical, painting and repair services.",
        "status": "enabled",
        "subcategories_count": 3,
        "created_by": {
            "id": 1,
            "name": "System Administrator"
        },
        "created_at": "2026-08-12T08:00:00+00:00",
        "updated_at": "2026-08-12T09:00:00+00:00"
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

#### HTTP 403: Missing the manage service categories permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Service category not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error (e.g. duplicate name)

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "name": [
            "A service category with this name already exists."
        ]
    },
    "meta": []
}
```

## `PUT /api/service-categories/{serviceCategory}`

PUT/PATCH /api/service-categories/{serviceCategory} — update name/description.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `serviceCategory` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `name` | no | string, maxLength=255 |
| `description` | no | string, maxLength=1000 |
| `status` | no | string, one of: `enabled`, `disabled` |

Example request body:

```json
{
    "name": "Home Maintenance & Repair",
    "description": "Plumbing, electrical, painting and repair services."
}
```

### Responses

#### HTTP 200: Service category updated

```json
{
    "success": true,
    "message": "Service category updated.",
    "data": {
        "id": 1,
        "name": "Home Maintenance & Repair",
        "description": "Plumbing, electrical, painting and repair services.",
        "status": "enabled",
        "subcategories_count": 3,
        "created_by": {
            "id": 1,
            "name": "System Administrator"
        },
        "created_at": "2026-08-12T08:00:00+00:00",
        "updated_at": "2026-08-12T09:00:00+00:00"
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

#### HTTP 403: Missing the manage service categories permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Service category not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error (e.g. duplicate name)

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "name": [
            "A service category with this name already exists."
        ]
    },
    "meta": []
}
```

## `PATCH /api/service-categories/{serviceCategory}/status`

Disabled categories remain in the database but are no longer selectable or displayed on the platform. They are never physically deleted by this operation.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `serviceCategory` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `status` | yes | string, one of: `enabled`, `disabled` |

Example request body:

```json
{
    "status": "disabled"
}
```

### Responses

#### HTTP 200: Service category status updated

```json
{
    "success": true,
    "message": "Service category status updated.",
    "data": {
        "id": 1,
        "name": "Home Maintenance",
        "description": "Plumbing, electrical and painting services.",
        "status": "disabled",
        "subcategories_count": 3,
        "created_by": {
            "id": 1,
            "name": "System Administrator"
        },
        "created_at": "2026-08-12T08:00:00+00:00",
        "updated_at": "2026-08-12T09:00:00+00:00"
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

#### HTTP 403: Missing the manage service categories permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Service category not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error / invalid status value

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "status": [
            "The selected status is invalid."
        ]
    },
    "meta": []
}
```

## `POST /api/service-categories/{serviceCategory}/subcategories`

POST /api/service-categories/{serviceCategory}/subcategories — create a subcategory.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `serviceCategory` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `name` | yes | string, maxLength=255 |
| `description` | no | string, maxLength=1000 |
| `status` | no | string, one of: `enabled`, `disabled` |

Example request body:

```json
{
    "name": "Plumbing",
    "description": "Pipe installation, repair and maintenance."
}
```

### Responses

#### HTTP 201: Subcategory created

```json
{
    "success": true,
    "message": "Subcategory created.",
    "data": {
        "id": 1,
        "category_id": 1,
        "name": "Plumbing",
        "description": "Pipe installation, repair and maintenance.",
        "status": "enabled",
        "created_at": "2026-08-12T08:00:00+00:00",
        "updated_at": "2026-08-12T08:00:00+00:00"
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

#### HTTP 403: Missing the manage service categories permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Parent service category not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error (e.g. duplicate name within the category)

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "name": [
            "A subcategory with this name already exists in this category."
        ]
    },
    "meta": []
}
```

## `DELETE /api/service-categories/{serviceCategory}/subcategories/{serviceSubcategory}`

Soft-deletes the subcategory. The subcategory must belong to the parent category in the URL.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `serviceCategory` | path | yes | integer |
| `serviceSubcategory` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Subcategory deleted (soft delete)

```json
{
    "success": true,
    "message": "Subcategory deleted.",
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

#### HTTP 403: Missing the manage service categories permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Category or subcategory not found (or subcategory does not belong to the category)

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Deletion guard violated (subcategory already deleted)

```json
{
    "success": false,
    "message": "The subcategory is already deleted.",
    "data": [],
    "errors": {
        "id": [
            "The subcategory is already deleted."
        ]
    },
    "meta": []
}
```

## `PATCH /api/service-categories/{serviceCategory}/subcategories/{serviceSubcategory}`

The subcategory must belong to the parent category in the URL.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `serviceCategory` | path | yes | integer |
| `serviceSubcategory` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `name` | no | string, maxLength=255 |
| `description` | no | string, maxLength=1000 |
| `status` | no | string, one of: `enabled`, `disabled` |

Example request body:

```json
{
    "name": "Emergency Plumbing",
    "description": "24/7 emergency pipe repair.",
    "status": "enabled"
}
```

### Responses

#### HTTP 200: Subcategory updated

```json
{
    "success": true,
    "message": "Subcategory updated.",
    "data": {
        "id": 1,
        "category_id": 1,
        "name": "Emergency Plumbing",
        "description": "24/7 emergency pipe repair.",
        "status": "enabled",
        "created_at": "2026-08-12T08:00:00+00:00",
        "updated_at": "2026-08-12T09:00:00+00:00"
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

#### HTTP 403: Missing the manage service categories permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Category or subcategory not found (or subcategory does not belong to the category)

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error (e.g. duplicate name within the category)

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "name": [
            "A subcategory with this name already exists in this category."
        ]
    },
    "meta": []
}
```

## `PUT /api/service-categories/{serviceCategory}/subcategories/{serviceSubcategory}`

The subcategory must belong to the parent category in the URL.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `serviceCategory` | path | yes | integer |
| `serviceSubcategory` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `name` | no | string, maxLength=255 |
| `description` | no | string, maxLength=1000 |
| `status` | no | string, one of: `enabled`, `disabled` |

Example request body:

```json
{
    "name": "Emergency Plumbing",
    "description": "24/7 emergency pipe repair.",
    "status": "enabled"
}
```

### Responses

#### HTTP 200: Subcategory updated

```json
{
    "success": true,
    "message": "Subcategory updated.",
    "data": {
        "id": 1,
        "category_id": 1,
        "name": "Emergency Plumbing",
        "description": "24/7 emergency pipe repair.",
        "status": "enabled",
        "created_at": "2026-08-12T08:00:00+00:00",
        "updated_at": "2026-08-12T09:00:00+00:00"
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

#### HTTP 403: Missing the manage service categories permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Category or subcategory not found (or subcategory does not belong to the category)

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error (e.g. duplicate name within the category)

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "name": [
            "A subcategory with this name already exists in this category."
        ]
    },
    "meta": []
}
```

