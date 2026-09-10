# Providers

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/providers`

GET /api/providers — paginated, searchable, filterable list of providers.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `status` | query | no | string (`active`, `suspended`) |
| `verification` | query | no | string (`unverified`, `pending`, `verified`, `rejected`, `additional_info_required`) |
| `sort` | query | no | string (`created_at`, `average_rating`, `total_bookings`, `business_name`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated list of providers

```json
{
    "success": true,
    "message": "Providers retrieved.",
    "data": [
        {
            "id": 1,
            "user_id": 2,
            "user": {
                "id": 2,
                "name": "John Smith",
                "email": "john@example.com",
                "phone": "+1234567890",
                "created_at": "2026-08-01T08:00:00+00:00"
            },
            "business_name": "Smith Plumbing Co.",
            "bio": "Experienced plumber with 10 years in residential and commercial work.",
            "specialization": "Plumbing",
            "experience_years": 10,
            "hourly_rate": "65.00",
            "location": "New York, NY",
            "website": "https://smithplumbing.example.com",
            "social_links": {
                "linkedin": "https://linkedin.com/in/johnsmith"
            },
            "portfolio": [],
            "skills": [
                "Pipe Repair",
                "Water Heater Installation",
                "Drain Cleaning"
            ],
            "certifications": [
                "Licensed Plumber - NY"
            ],
            "languages": [
                "English",
                "Spanish"
            ],
            "average_rating": "4.80",
            "total_reviews": 45,
            "total_bookings": 120,
            "completed_bookings": 115,
            "verification_status": "verified",
            "verified_at": "2026-08-05T10:00:00+00:00",
            "verified_by": {
                "id": 1,
                "name": "Admin User"
            },
            "rejection_reason": null,
            "is_suspended": false,
            "suspended_at": null,
            "suspended_by": null,
            "suspension_reason": null,
            "latest_verification_request": null,
            "created_at": "2026-08-01T08:00:00+00:00",
            "updated_at": "2026-08-12T09:00:00+00:00"
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

#### HTTP 403: Missing the manage providers permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `GET /api/providers/{provider}`

GET /api/providers/{provider} — detailed provider profile.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `provider` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Provider profile details

```json
{
    "success": true,
    "message": "Request successful.",
    "data": {
        "id": 1,
        "user_id": 2,
        "user": {
            "id": 2,
            "name": "John Smith",
            "email": "john@example.com",
            "phone": "+1234567890",
            "created_at": "2026-08-01T08:00:00+00:00"
        },
        "business_name": "Smith Plumbing Co.",
        "bio": "Experienced plumber with 10 years in residential and commercial work.",
        "specialization": "Plumbing",
        "experience_years": 10,
        "hourly_rate": "65.00",
        "location": "New York, NY",
        "website": "https://smithplumbing.example.com",
        "social_links": {
            "linkedin": "https://linkedin.com/in/johnsmith"
        },
        "portfolio": [],
        "skills": [
            "Pipe Repair",
            "Water Heater Installation",
            "Drain Cleaning"
        ],
        "certifications": [
            "Licensed Plumber - NY"
        ],
        "languages": [
            "English",
            "Spanish"
        ],
        "average_rating": "4.80",
        "total_reviews": 45,
        "total_bookings": 120,
        "completed_bookings": 115,
        "verification_status": "verified",
        "verified_at": "2026-08-05T10:00:00+00:00",
        "verified_by": {
            "id": 1,
            "name": "Admin User"
        },
        "rejection_reason": null,
        "is_suspended": false,
        "suspended_at": null,
        "suspended_by": null,
        "suspension_reason": null,
        "latest_verification_request": {
            "id": 5,
            "provider_profile_id": 1,
            "status": "approved",
            "notes": null,
            "admin_notes": null,
            "rejection_reason": null,
            "additional_info_request": null,
            "submitted_at": "2026-08-04T09:00:00+00:00",
            "reviewed_at": "2026-08-05T10:00:00+00:00",
            "reviewed_by": {
                "id": 1,
                "name": "Admin User"
            },
            "documents": [
                {
                    "id": 10,
                    "verification_request_id": 5,
                    "document_type": "government_id",
                    "file_name": "drivers_license.pdf",
                    "file_mime_type": "application/pdf",
                    "file_size": 1048576,
                    "formatted_file_size": "1 MB",
                    "description": "Government-issued driver license",
                    "created_at": "2026-08-04T09:00:00+00:00"
                }
            ],
            "documents_count": 1,
            "created_at": "2026-08-04T09:00:00+00:00",
            "updated_at": "2026-08-05T10:00:00+00:00"
        },
        "created_at": "2026-08-01T08:00:00+00:00",
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

#### HTTP 403: Missing the manage providers permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Provider not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/providers/{provider}/activate`

PATCH /api/providers/{provider}/activate — activate a suspended provider.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `provider` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Provider activated

```json
{
    "success": true,
    "message": "Provider activated.",
    "data": {
        "id": 1,
        "user_id": 2,
        "user": {
            "id": 2,
            "name": "John Smith",
            "email": "john@example.com",
            "phone": "+1234567890",
            "created_at": "2026-08-01T08:00:00+00:00"
        },
        "business_name": "Smith Plumbing Co.",
        "bio": "Experienced plumber with 10 years in residential and commercial work.",
        "specialization": "Plumbing",
        "experience_years": 10,
        "hourly_rate": "65.00",
        "location": "New York, NY",
        "website": "https://smithplumbing.example.com",
        "social_links": {
            "linkedin": "https://linkedin.com/in/johnsmith"
        },
        "portfolio": [],
        "skills": [
            "Pipe Repair",
            "Water Heater Installation",
            "Drain Cleaning"
        ],
        "certifications": [
            "Licensed Plumber - NY"
        ],
        "languages": [
            "English",
            "Spanish"
        ],
        "average_rating": "4.80",
        "total_reviews": 45,
        "total_bookings": 120,
        "completed_bookings": 115,
        "verification_status": "verified",
        "verified_at": "2026-08-05T10:00:00+00:00",
        "verified_by": {
            "id": 1,
            "name": "Admin User"
        },
        "rejection_reason": null,
        "is_suspended": false,
        "suspended_at": null,
        "suspended_by": null,
        "suspension_reason": null,
        "latest_verification_request": null,
        "created_at": "2026-08-01T08:00:00+00:00",
        "updated_at": "2026-08-12T10:00:00+00:00"
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

#### HTTP 403: Missing the manage providers permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Provider not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Not currently suspended

```json
{
    "success": false,
    "message": "Provider is not currently suspended.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/providers/{provider}/suspend`

PATCH /api/providers/{provider}/suspend — suspend a provider.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `provider` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `reason` | yes | string, maxLength=500 |

Example request body:

```json
{
    "reason": "Violation of platform terms."
}
```

### Responses

#### HTTP 200: Provider suspended

```json
{
    "success": true,
    "message": "Provider suspended.",
    "data": {
        "id": 1,
        "user_id": 2,
        "user": {
            "id": 2,
            "name": "John Smith",
            "email": "john@example.com",
            "phone": "+1234567890",
            "created_at": "2026-08-01T08:00:00+00:00"
        },
        "business_name": "Smith Plumbing Co.",
        "bio": "Experienced plumber with 10 years in residential and commercial work.",
        "specialization": "Plumbing",
        "experience_years": 10,
        "hourly_rate": "65.00",
        "location": "New York, NY",
        "website": "https://smithplumbing.example.com",
        "social_links": {
            "linkedin": "https://linkedin.com/in/johnsmith"
        },
        "portfolio": [],
        "skills": [
            "Pipe Repair",
            "Water Heater Installation",
            "Drain Cleaning"
        ],
        "certifications": [
            "Licensed Plumber - NY"
        ],
        "languages": [
            "English",
            "Spanish"
        ],
        "average_rating": "4.80",
        "total_reviews": 45,
        "total_bookings": 120,
        "completed_bookings": 115,
        "verification_status": "verified",
        "verified_at": "2026-08-05T10:00:00+00:00",
        "verified_by": {
            "id": 1,
            "name": "Admin User"
        },
        "rejection_reason": null,
        "is_suspended": true,
        "suspended_at": "2026-08-12T10:00:00+00:00",
        "suspended_by": {
            "id": 1,
            "name": "Admin User"
        },
        "suspension_reason": "Violation of platform terms.",
        "latest_verification_request": null,
        "created_at": "2026-08-01T08:00:00+00:00",
        "updated_at": "2026-08-12T10:00:00+00:00"
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

#### HTTP 403: Missing the manage providers permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Provider not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error or already suspended

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "reason": [
            "The reason field is required."
        ]
    },
    "meta": []
}
```

## `GET /api/providers/{provider}/verification-documents/{document}/download`

Downloads a verification document only after checking the provider scope and the view-providers permission. The file is served from private storage.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `provider` | path | yes | integer |
| `document` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Private verification document download

Response schema: `see openapi.json`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Provider, document, or private file not found

Response schema: `see openapi.json`

## `GET /api/providers/{provider}/verification-history`

GET /api/providers/{provider}/verification-history — verification request history.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `provider` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Verification history (newest first)

```json
{
    "success": true,
    "message": "Verification history retrieved.",
    "data": [
        {
            "id": 5,
            "provider_profile_id": 1,
            "status": "approved",
            "notes": null,
            "admin_notes": "All documents verified.",
            "rejection_reason": null,
            "additional_info_request": null,
            "submitted_at": "2026-08-04T09:00:00+00:00",
            "reviewed_at": "2026-08-05T10:00:00+00:00",
            "reviewed_by": {
                "id": 1,
                "name": "Admin User"
            },
            "documents": [
                {
                    "id": 10,
                    "verification_request_id": 5,
                    "document_type": "government_id",
                    "file_name": "drivers_license.pdf",
                    "file_mime_type": "application/pdf",
                    "file_size": 1048576,
                    "formatted_file_size": "1 MB",
                    "description": "Government-issued driver license",
                    "created_at": "2026-08-04T09:00:00+00:00"
                }
            ],
            "documents_count": 1,
            "created_at": "2026-08-04T09:00:00+00:00",
            "updated_at": "2026-08-05T10:00:00+00:00"
        },
        {
            "id": 3,
            "provider_profile_id": 1,
            "status": "rejected",
            "notes": null,
            "admin_notes": null,
            "rejection_reason": "Documents are unclear and illegible.",
            "additional_info_request": null,
            "submitted_at": "2026-07-15T09:00:00+00:00",
            "reviewed_at": "2026-07-16T14:00:00+00:00",
            "reviewed_by": {
                "id": 1,
                "name": "Admin User"
            },
            "documents": [
                {
                    "id": 7,
                    "verification_request_id": 3,
                    "document_type": "government_id",
                    "file_name": "blurry_id.jpg",
                    "file_mime_type": "image/jpeg",
                    "file_size": 524288,
                    "formatted_file_size": "512 KB",
                    "description": "Blurred government ID photo",
                    "created_at": "2026-07-15T09:00:00+00:00"
                }
            ],
            "documents_count": 1,
            "created_at": "2026-07-15T09:00:00+00:00",
            "updated_at": "2026-07-16T14:00:00+00:00"
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

#### HTTP 403: Missing the manage providers permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Provider not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/providers/{provider}/verification/approve`

PATCH /api/providers/{provider}/verification/approve — approve verification.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `provider` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `notes` | no | string, maxLength=1000 |

Example request body:

```json
{
    "notes": "All documents verified successfully."
}
```

### Responses

#### HTTP 200: Provider verification approved

```json
{
    "success": true,
    "message": "Provider verification approved.",
    "data": {
        "id": 1,
        "user_id": 2,
        "user": {
            "id": 2,
            "name": "John Smith",
            "email": "john@example.com",
            "phone": "+1234567890",
            "created_at": "2026-08-01T08:00:00+00:00"
        },
        "business_name": "Smith Plumbing Co.",
        "bio": "Experienced plumber with 10 years in residential and commercial work.",
        "specialization": "Plumbing",
        "experience_years": 10,
        "hourly_rate": "65.00",
        "location": "New York, NY",
        "website": "https://smithplumbing.example.com",
        "social_links": {
            "linkedin": "https://linkedin.com/in/johnsmith"
        },
        "portfolio": [],
        "skills": [
            "Pipe Repair",
            "Water Heater Installation",
            "Drain Cleaning"
        ],
        "certifications": [
            "Licensed Plumber - NY"
        ],
        "languages": [
            "English",
            "Spanish"
        ],
        "average_rating": "4.80",
        "total_reviews": 45,
        "total_bookings": 120,
        "completed_bookings": 115,
        "verification_status": "verified",
        "verified_at": "2026-08-12T10:00:00+00:00",
        "verified_by": {
            "id": 1,
            "name": "Admin User"
        },
        "rejection_reason": null,
        "is_suspended": false,
        "suspended_at": null,
        "suspended_by": null,
        "suspension_reason": null,
        "latest_verification_request": null,
        "created_at": "2026-08-01T08:00:00+00:00",
        "updated_at": "2026-08-12T10:00:00+00:00"
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

#### HTTP 403: Missing the manage providers permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Provider not found or no pending verification request

```json
{
    "success": false,
    "message": "No pending verification request found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error or invalid state

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "notes": [
            "The notes field must not exceed 1000 characters."
        ]
    },
    "meta": []
}
```

## `PATCH /api/providers/{provider}/verification/reject`

PATCH /api/providers/{provider}/verification/reject — reject verification.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `provider` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `reason` | yes | string, maxLength=1000 |

Example request body:

```json
{
    "reason": "Documents are unclear and illegible."
}
```

### Responses

#### HTTP 200: Provider verification rejected

```json
{
    "success": true,
    "message": "Provider verification rejected.",
    "data": {
        "id": 1,
        "user_id": 2,
        "user": {
            "id": 2,
            "name": "John Smith",
            "email": "john@example.com",
            "phone": "+1234567890",
            "created_at": "2026-08-01T08:00:00+00:00"
        },
        "business_name": "Smith Plumbing Co.",
        "bio": "Experienced plumber with 10 years in residential and commercial work.",
        "specialization": "Plumbing",
        "experience_years": 10,
        "hourly_rate": "65.00",
        "location": "New York, NY",
        "website": "https://smithplumbing.example.com",
        "social_links": {
            "linkedin": "https://linkedin.com/in/johnsmith"
        },
        "portfolio": [],
        "skills": [
            "Pipe Repair",
            "Water Heater Installation",
            "Drain Cleaning"
        ],
        "certifications": [
            "Licensed Plumber - NY"
        ],
        "languages": [
            "English",
            "Spanish"
        ],
        "average_rating": "4.80",
        "total_reviews": 45,
        "total_bookings": 120,
        "completed_bookings": 115,
        "verification_status": "rejected",
        "verified_at": null,
        "verified_by": null,
        "rejection_reason": "Documents are unclear and illegible.",
        "is_suspended": false,
        "suspended_at": null,
        "suspended_by": null,
        "suspension_reason": null,
        "latest_verification_request": null,
        "created_at": "2026-08-01T08:00:00+00:00",
        "updated_at": "2026-08-12T10:00:00+00:00"
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

#### HTTP 403: Missing the manage providers permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Provider not found or no pending verification request

```json
{
    "success": false,
    "message": "No pending verification request found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error or invalid state

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "reason": [
            "The reason field is required."
        ]
    },
    "meta": []
}
```

## `PATCH /api/providers/{provider}/verification/remove`

PATCH /api/providers/{provider}/verification/remove — remove verified status.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `provider` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Provider verification removed

```json
{
    "success": true,
    "message": "Provider verification removed.",
    "data": {
        "id": 1,
        "user_id": 2,
        "user": {
            "id": 2,
            "name": "John Smith",
            "email": "john@example.com",
            "phone": "+1234567890",
            "created_at": "2026-08-01T08:00:00+00:00"
        },
        "business_name": "Smith Plumbing Co.",
        "bio": "Experienced plumber with 10 years in residential and commercial work.",
        "specialization": "Plumbing",
        "experience_years": 10,
        "hourly_rate": "65.00",
        "location": "New York, NY",
        "website": "https://smithplumbing.example.com",
        "social_links": {
            "linkedin": "https://linkedin.com/in/johnsmith"
        },
        "portfolio": [],
        "skills": [
            "Pipe Repair",
            "Water Heater Installation",
            "Drain Cleaning"
        ],
        "certifications": [
            "Licensed Plumber - NY"
        ],
        "languages": [
            "English",
            "Spanish"
        ],
        "average_rating": "4.80",
        "total_reviews": 45,
        "total_bookings": 120,
        "completed_bookings": 115,
        "verification_status": "unverified",
        "verified_at": null,
        "verified_by": null,
        "rejection_reason": null,
        "is_suspended": false,
        "suspended_at": null,
        "suspended_by": null,
        "suspension_reason": null,
        "latest_verification_request": null,
        "created_at": "2026-08-01T08:00:00+00:00",
        "updated_at": "2026-08-12T10:00:00+00:00"
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

#### HTTP 403: Missing the manage providers permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Provider not found

```json
{
    "success": false,
    "message": "Resource not found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Not currently verified

```json
{
    "success": false,
    "message": "Provider is not currently verified.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/providers/{provider}/verification/request-info`

PATCH /api/providers/{provider}/verification/request-info — request additional info.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `provider` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `message` | yes | string, maxLength=2000 |

Example request body:

```json
{
    "message": "Please provide a clearer copy of your government ID."
}
```

### Responses

#### HTTP 200: Additional information requested

```json
{
    "success": true,
    "message": "Additional information requested.",
    "data": {
        "id": 1,
        "user_id": 2,
        "user": {
            "id": 2,
            "name": "John Smith",
            "email": "john@example.com",
            "phone": "+1234567890",
            "created_at": "2026-08-01T08:00:00+00:00"
        },
        "business_name": "Smith Plumbing Co.",
        "bio": "Experienced plumber with 10 years in residential and commercial work.",
        "specialization": "Plumbing",
        "experience_years": 10,
        "hourly_rate": "65.00",
        "location": "New York, NY",
        "website": "https://smithplumbing.example.com",
        "social_links": {
            "linkedin": "https://linkedin.com/in/johnsmith"
        },
        "portfolio": [],
        "skills": [
            "Pipe Repair",
            "Water Heater Installation",
            "Drain Cleaning"
        ],
        "certifications": [
            "Licensed Plumber - NY"
        ],
        "languages": [
            "English",
            "Spanish"
        ],
        "average_rating": "4.80",
        "total_reviews": 45,
        "total_bookings": 120,
        "completed_bookings": 115,
        "verification_status": "additional_info_required",
        "verified_at": null,
        "verified_by": null,
        "rejection_reason": null,
        "is_suspended": false,
        "suspended_at": null,
        "suspended_by": null,
        "suspension_reason": null,
        "latest_verification_request": null,
        "created_at": "2026-08-01T08:00:00+00:00",
        "updated_at": "2026-08-12T10:00:00+00:00"
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

#### HTTP 403: Missing the manage providers permission

```json
{
    "success": false,
    "message": "This action is unauthorized.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Provider not found or no pending verification request

```json
{
    "success": false,
    "message": "No pending verification request found.",
    "data": [],
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Validation error or invalid state

```json
{
    "success": false,
    "message": "The given data was invalid.",
    "data": [],
    "errors": {
        "message": [
            "The message field is required."
        ]
    },
    "meta": []
}
```

