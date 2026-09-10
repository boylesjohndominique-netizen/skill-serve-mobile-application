# Bookings

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/bookings`

GET /api/bookings — paginated, searchable, filterable list.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `status` | query | no | string (`pending`, `confirmed`, `active`, `completed`, `cancelled`, `disputed`) |
| `payment_status` | query | no | string (`unpaid`, `paid`, `refunded`, `partially_refunded`) |
| `provider_id` | query | no | integer |
| `client_id` | query | no | integer |
| `service_id` | query | no | integer |
| `dispute_status` | query | no | string (`pending`, `investigated`, `resolved`, `rejected`, `closed`) |
| `date_from` | query | no | string |
| `date_to` | query | no | string |
| `sort` | query | no | string (`booking_number`, `created_at`, `total_price`, `status`, `scheduled_date`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated list of bookings

```json
{
    "success": true,
    "message": "Bookings retrieved.",
    "data": [
        {
            "id": 1,
            "booking_number": "BK-2026-000001",
            "status": "pending",
            "payment_status": "unpaid",
            "total_price": 150,
            "service_price": 150,
            "platform_fee": 15,
            "currency": "USD",
            "scheduled_date": "2026-09-01T10:00:00+00:00",
            "service": {
                "id": 1,
                "title": "Emergency Pipe Repair"
            },
            "client": {
                "id": 3,
                "name": "Alice Customer"
            },
            "provider": {
                "id": 1,
                "business_name": "Garcia Plumbing Solutions"
            },
            "created_at": "2026-08-20T12:00:00+00:00"
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

Response schema: `see openapi.json`

#### HTTP 403: Missing the view bookings permission

Response schema: `see openapi.json`

## `GET /api/bookings/{booking}`

GET /api/bookings/{booking} — a single booking with relationships.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Booking details

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

## `PATCH /api/bookings/{booking}/cancel`

PATCH /api/bookings/{booking}/cancel — cancel a booking.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `reason` | no | string, maxLength=1000 |

Example request body:

```json
{
    "reason": "Client requested cancellation."
}
```

### Responses

#### HTTP 200: Booking cancelled. Unpaid bookings remain unpaid. Paid or partially paid bookings retain their payment status; no external refund is processed by this endpoint.

```json
{
    "success": true,
    "message": "Booking cancelled.",
    "data": {
        "id": 1,
        "status": "cancelled"
    },
    "errors": null,
    "meta": []
}
```

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

#### HTTP 422: Booking cannot be cancelled (state guard)

```json
{
    "success": false,
    "message": "This booking cannot be cancelled in its current status.",
    "data": [],
    "errors": null,
    "meta": []
}
```

## `PATCH /api/bookings/{booking}/dispute`

PATCH /api/bookings/{booking}/dispute — manage a booking dispute.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |

### Request body and validation

| Field | Required | Validation / type |
|---|---:|---|
| `action` | yes | string, one of: `investigate`, `resolve`, `reject` |
| `resolution` | no | string, maxLength=2000 |
| `notes` | no | string, maxLength=2000 |

Example request body:

```json
{
    "action": "resolve",
    "resolution": "Refund issued to client."
}
```

### Responses

#### HTTP 200: Dispute managed

```json
{
    "success": true,
    "message": "Dispute resolved.",
    "data": {
        "id": 1,
        "dispute_status": "resolved"
    },
    "errors": null,
    "meta": []
}
```

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

#### HTTP 422: Validation error

Response schema: `see openapi.json`

## `GET /api/bookings/{booking}/history`

GET /api/bookings/{booking}/history — booking status change history.

**Authentication:** Bearer token

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `booking` | path | yes | integer |
| `page` | query | no | integer |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Paginated booking history

Response schema: `#/components/schemas/ApiEnvelope`

#### HTTP 401: Unauthenticated

Response schema: `see openapi.json`

#### HTTP 403: Unauthorized

Response schema: `see openapi.json`

#### HTTP 404: Booking not found

Response schema: `see openapi.json`

