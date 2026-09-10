# Client Marketplace

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/categories`

List enabled service categories and subcategories

**Authentication:** Public

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Enabled categories

Response schema: `#/components/schemas/ClientCategoryListEnvelope`

## `GET /api/client/v1/categories/{category}`

Get an enabled category

**Authentication:** Public

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `category` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Category details

Response schema: `#/components/schemas/ClientCategoryEnvelope`

#### HTTP 404: Category not found or disabled

Response schema: `see openapi.json`

## `GET /api/client/v1/providers`

List verified active providers

**Authentication:** Public

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `category_id` | query | no | integer |
| `subcategory_id` | query | no | integer |
| `sort` | query | no | string (`created_at`, `average_rating`, `business_name`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Verified providers

Response schema: `#/components/schemas/ClientProviderListEnvelope`

## `GET /api/client/v1/providers/{provider}`

Get a verified active provider

**Authentication:** Public

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `provider` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Provider details

Response schema: `#/components/schemas/ClientProviderEnvelope`

#### HTTP 404: Provider not found or unavailable

Response schema: `see openapi.json`

## `GET /api/client/v1/services`

List bookable published services

**Authentication:** Public

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `search` | query | no | string |
| `category_id` | query | no | integer |
| `subcategory_id` | query | no | integer |
| `provider_id` | query | no | integer |
| `sort` | query | no | string (`created_at`, `title`, `price`, `average_rating`) |
| `direction` | query | no | string (`asc`, `desc`) |
| `per_page` | query | no | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Published services

Response schema: `#/components/schemas/ClientServiceListEnvelope`

## `GET /api/client/v1/services/{service}`

Get a bookable service

**Authentication:** Public

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `service` | path | yes | integer |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Service details

Response schema: `#/components/schemas/ClientServiceEnvelope`

#### HTTP 404: Service not found or unavailable

Response schema: `see openapi.json`

