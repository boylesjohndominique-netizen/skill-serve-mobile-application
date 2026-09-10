# Services

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/services`

GET /api/services — paginated, searchable, filterable list.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `status` | query | no | string (`draft`, `published`, `archived`) |
| `approval_status` | query | no | string (`pending`, `approved`, `rejected`) |
| `category_id` | query | no | integer |
| `provider_id` | query | no | integer |
| `is_featured` | query | no | boolean |
| `is_hidden` | query | no | boolean |
| `sort` | query | no | string (`title`, `created_at`, `average_rating`, `price`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated list of services

```json
{
    "success": true,
    "message": "Services retrieved.",
    "data": [
        {
            "id": 1,
            "title": "Emergency Pipe Repair",
            "description": "Fast, reliable emergency pipe repair.",
            "price": 150,
            "price_type": "fixed",
            "currency": "USD",
            "duration": "1-2 hours",
            "location": "Austin, TX",
            "status": "published",
            "approval_status": "approved",
            "rejection_reason": null,
            "is_featured": true,
            "is_hidden": false,
            "total_bookings": 310,
            "completed_bookings": 298,
            "average_rating": 4.8,
            "total_reviews": 92,
            "provider": {
                "id": 1,
                "business_name": "Garcia Plumbing Solutions",
                "user": {
                    "id": 1,
                    "name": "Maria Garcia",
                    "email": "maria.garcia@example.com"
                }
            },
            "category": {
                "id": 1,
                "name": "Home Maintenance"
            },
            "subcategory": {
                "id": 1,
                "name": "Plumbing"
            },
            "approved_by": {
                "id": 1,
                "name": "System Administrator"
            },
            "approved_at": "2026-08-15T10:00:00+00:00",
            "created_at": "2026-08-10T08:00:00+00:00",
            "updated_at": "2026-08-15T10:00:00+00:00"
        }
    ],
    "errors": null,
    "meta": {
        "pagination": {
            "total": 40,
            "per_page": 15,
            "current_page": 1,
            "last_page": 3,
            "from": 1,
            "to": 15
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

#### HTTP 403: Missing the view services permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `POST /api/services`

POST /api/services — create a new service.

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `title` | yes | string, maxLength=255 |
| `description` | no | string, maxLength=5000 |
| `provider_id` | yes | integer |
| `category_id` | yes | integer |
| `subcategory_id` | no | integer |
| `price` | no | number, format=float |
| `price_type` | no | string, one of: `fixed`, `hourly`, `custom` |
| `currency` | no | string, maxLength=3 |
| `duration` | no | string, maxLength=100 |
| `location` | no | string, maxLength=255 |

Example request body:

```json
{
    "title": "Plumbing Repair",
    "description": "Expert plumbing repair service.",
    "provider_id": 1,
    "category_id": 1,
    "subcategory_id": 1,
    "price": 150,
    "price_type": "fixed",
    "currency": "USD",
    "duration": "1-2 hours",
    "location": "Austin, TX"
}
```

### Responses

#### HTTP 201: Service created

```json
{
    "success": true,
    "message": "Service created.",
    "data": {
        "id": 41,
        "title": "Plumbing Repair",
        "description": "Expert plumbing repair service.",
        "price": 150,
        "price_type": "fixed",
        "currency": "USD",
        "duration": "1-2 hours",
        "location": "Austin, TX",
        "status": "draft",
        "approval_status": "pending",
        "rejection_reason": null,
        "is_featured": false,
        "is_hidden": false,
        "total_bookings": 0,
        "completed_bookings": 0,
        "average_rating": 0,
        "total_reviews": 0,
        "provider": {
            "id": 1,
            "business_name": "Garcia Plumbing Solutions",
            "user": {
                "id": 1,
                "name": "Maria Garcia",
                "email": "maria.garcia@example.com"
            }
        },
        "category": {
            "id": 1,
            "name": "Home Maintenance"
        },
        "subcategory": {
            "id": 1,
            "name": "Plumbing"
        },
        "created_at": "2026-08-20T12:00:00+00:00",
        "updated_at": "2026-08-20T12:00:00+00:00"
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

#### HTTP 403: Missing the create services permission

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
    "message": "Validation failed.",
    "data": [],
    "errors": {
        "title": [
            "The title field is required."
        ],
        "category_id": [
            "The category id field is required."
        ]
    },
    "meta": []
}
```

## `DELETE /api/services/{service}`

Soft-deletes the service.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `service` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Service deleted (soft delete)

```json
{
    "success": true,
    "message": "Service deleted.",
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

#### HTTP 403: Missing the delete services permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Service not found

```json
{
    "success": false,
    "message": "Service not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `GET /api/services/{service}`

GET /api/services/{service} — a single service with relationships.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `service` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Service details

```json
{
    "success": true,
    "message": "Request successful.",
    "data": {
        "id": 1,
        "title": "Emergency Pipe Repair",
        "description": "Fast, reliable emergency pipe repair.",
        "price": 150,
        "price_type": "fixed",
        "currency": "USD",
        "duration": "1-2 hours",
        "location": "Austin, TX",
        "status": "published",
        "approval_status": "approved",
        "rejection_reason": null,
        "is_featured": true,
        "is_hidden": false,
        "total_bookings": 310,
        "completed_bookings": 298,
        "average_rating": 4.8,
        "total_reviews": 92,
        "provider": {
            "id": 1,
            "business_name": "Garcia Plumbing Solutions",
            "user": {
                "id": 1,
                "name": "Maria Garcia",
                "email": "maria.garcia@example.com"
            }
        },
        "category": {
            "id": 1,
            "name": "Home Maintenance"
        },
        "subcategory": {
            "id": 1,
            "name": "Plumbing"
        },
        "created_by": {
            "id": 1,
            "name": "System Administrator"
        },
        "updated_by": {
            "id": 1,
            "name": "System Administrator"
        },
        "approved_by": {
            "id": 1,
            "name": "System Administrator"
        },
        "approved_at": "2026-08-15T10:00:00+00:00",
        "created_at": "2026-08-10T08:00:00+00:00",
        "updated_at": "2026-08-15T10:00:00+00:00"
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

#### HTTP 403: Missing the view services permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Service not found

```json
{
    "success": false,
    "message": "Service not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/services/{service}`

PUT/PATCH /api/services/{service} — update service information.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `service` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `title` | no | string, maxLength=255 |
| `description` | no | string, maxLength=5000 |
| `category_id` | no | integer |
| `subcategory_id` | no | integer |
| `price` | no | number, format=float |
| `price_type` | no | string, one of: `fixed`, `hourly`, `custom` |
| `currency` | no | string, maxLength=3 |
| `duration` | no | string, maxLength=100 |
| `location` | no | string, maxLength=255 |
| `status` | no | string, one of: `draft`, `published`, `archived` |
| `is_featured` | no | boolean |
| `is_hidden` | no | boolean |

Example request body:

```json
{
    "title": "Updated Service Title",
    "description": "Updated description.",
    "category_id": 1,
    "price": 200,
    "status": "published"
}
```

### Responses

#### HTTP 200: Service updated

```json
{
    "success": true,
    "message": "Service updated.",
    "data": {
        "id": 1,
        "title": "Updated Service Title",
        "description": "Updated description.",
        "price": 200,
        "price_type": "fixed",
        "currency": "USD",
        "status": "published",
        "approval_status": "approved",
        "is_featured": true,
        "is_hidden": false,
        "created_at": "2026-08-10T08:00:00+00:00",
        "updated_at": "2026-08-20T12:00:00+00:00"
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

#### HTTP 403: Missing the edit services permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Service not found

```json
{
    "success": false,
    "message": "Service not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error

```json
{
    "success": false,
    "message": "Validation failed.",
    "data": [],
    "errors": {
        "title": [
            "The title must not be greater than 255 characters."
        ]
    },
    "meta": []
}
```

## `PUT /api/services/{service}`

PUT/PATCH /api/services/{service} — update service information.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `service` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `title` | no | string, maxLength=255 |
| `description` | no | string, maxLength=5000 |
| `category_id` | no | integer |
| `subcategory_id` | no | integer |
| `price` | no | number, format=float |
| `price_type` | no | string, one of: `fixed`, `hourly`, `custom` |
| `currency` | no | string, maxLength=3 |
| `duration` | no | string, maxLength=100 |
| `location` | no | string, maxLength=255 |
| `status` | no | string, one of: `draft`, `published`, `archived` |
| `is_featured` | no | boolean |
| `is_hidden` | no | boolean |

Example request body:

```json
{
    "title": "Updated Service Title",
    "description": "Updated description.",
    "category_id": 1,
    "price": 200,
    "status": "published"
}
```

### Responses

#### HTTP 200: Service updated

```json
{
    "success": true,
    "message": "Service updated.",
    "data": {
        "id": 1,
        "title": "Updated Service Title",
        "description": "Updated description.",
        "price": 200,
        "price_type": "fixed",
        "currency": "USD",
        "status": "published",
        "approval_status": "approved",
        "is_featured": true,
        "is_hidden": false,
        "created_at": "2026-08-10T08:00:00+00:00",
        "updated_at": "2026-08-20T12:00:00+00:00"
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

#### HTTP 403: Missing the edit services permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Service not found

```json
{
    "success": false,
    "message": "Service not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error

```json
{
    "success": false,
    "message": "Validation failed.",
    "data": [],
    "errors": {
        "title": [
            "The title must not be greater than 255 characters."
        ]
    },
    "meta": []
}
```

## `PATCH /api/services/{service}/approve`

PATCH /api/services/{service}/approve — approve a service.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `service` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `notes` | no | string, maxLength=1000 |

Example request body:

```json
{
    "notes": "Service meets all quality standards."
}
```

### Responses

#### HTTP 200: Service approved

```json
{
    "success": true,
    "message": "Service approved.",
    "data": {
        "id": 1,
        "title": "Emergency Pipe Repair",
        "approval_status": "approved",
        "status": "published",
        "approved_by": {
            "id": 1,
            "name": "System Administrator"
        },
        "approved_at": "2026-08-20T12:00:00+00:00"
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

#### HTTP 403: Missing the approve services permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Service not found

```json
{
    "success": false,
    "message": "Service not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/services/{service}/feature`

PATCH /api/services/{service}/feature — feature/unfeature a service.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `service` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `is_featured` | yes | boolean |

Example request body:

```json
{
    "is_featured": true
}
```

### Responses

#### HTTP 200: Service featured status updated

```json
{
    "success": true,
    "message": "Service featured.",
    "data": {
        "id": 1,
        "title": "Emergency Pipe Repair",
        "is_featured": true
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

#### HTTP 403: Missing the feature services permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Service not found

```json
{
    "success": false,
    "message": "Service not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/services/{service}/hide`

PATCH /api/services/{service}/hide — hide/unhide a service.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `service` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `is_hidden` | yes | boolean |

Example request body:

```json
{
    "is_hidden": true
}
```

### Responses

#### HTTP 200: Service visibility updated

```json
{
    "success": true,
    "message": "Service hidden.",
    "data": {
        "id": 1,
        "title": "Emergency Pipe Repair",
        "is_hidden": true
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

#### HTTP 403: Missing the edit services permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Service not found

```json
{
    "success": false,
    "message": "Service not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/services/{service}/reject`

PATCH /api/services/{service}/reject — reject a service.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `service` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `reason` | yes | string, maxLength=1000 |

Example request body:

```json
{
    "reason": "Service description is incomplete."
}
```

### Responses

#### HTTP 200: Service rejected

```json
{
    "success": true,
    "message": "Service rejected.",
    "data": {
        "id": 1,
        "title": "Emergency Pipe Repair",
        "approval_status": "rejected",
        "status": "draft",
        "rejection_reason": "Service description is incomplete."
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

#### HTTP 403: Missing the reject services permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Service not found

```json
{
    "success": false,
    "message": "Service not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error (reason required)

```json
{
    "success": false,
    "message": "Validation failed.",
    "data": [],
    "errors": {
        "reason": [
            "The reason field is required."
        ]
    },
    "meta": []
}
```

