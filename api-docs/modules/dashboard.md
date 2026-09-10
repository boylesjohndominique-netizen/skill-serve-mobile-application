# Dashboard

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/dashboard`

Get dashboard summaries and analytics

**Authentication:** Bearer token

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Dashboard data

```json
{
    "success": true,
    "message": "Dashboard retrieved.",
    "data": {
        "user_summary": {
            "total_clients": 0,
            "total_providers": 0,
            "active_users": 0,
            "suspended_users": 0
        },
        "service_summary": {
            "total_services": 0,
            "approved_services": 0,
            "pending_services": 0,
            "reported_services": 0
        },
        "booking_summary": {
            "pending": 0,
            "confirmed": 0,
            "active": 0,
            "completed": 0,
            "cancelled": 0,
            "disputed": 0
        },
        "verification_summary": {
            "pending": 0,
            "approved": 0,
            "rejected": 0,
            "additional_info_required": 0
        },
        "reports_summary": {
            "pending": 0,
            "investigating": 0,
            "resolved": 0,
            "rejected": 0
        },
        "recent_activities": [],
        "analytics": {
            "monthly_activity": [],
            "booking_statuses": [],
            "user_statuses": []
        }
    }
}
```

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Dashboard permission required

Response schema: `see openapi.json`

