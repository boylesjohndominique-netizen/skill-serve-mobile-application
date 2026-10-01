# Locations

All examples and validation details in this file come from the Laravel backend OpenAPI attributes and request validation.

## `GET /api/client/v1/locations/match`

Used after scanning a National ID: the printed address (e.g. `123 RIZAL ST, BRGY BAGONG PAG-ASA, QUEZON CITY, METRO MANILA`) is matched to its region, province, city/municipality and barangay, and the part before them is returned as `street`. Tolerates ID spellings (`STA.`, `BRGY`, `X CITY` / `CITY OF X`) and a misread character. Anything it cannot decide is `null` rather than guessed — e.g. a municipality name shared by several provinces when no province is given — and the user confirms in the picker. `province` is null for NCR cities. No authentication.

**Authentication:** Public

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `address` | query | yes | string |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Best match

```json
{
    "success": true,
    "message": "Address matched.",
    "data": {
        "region": {
            "code": "130000000",
            "name": "National Capital Region (NCR)",
            "level": "region",
            "parent_code": null
        },
        "province": null,
        "city": {
            "code": "137404000",
            "name": "Quezon City",
            "level": "city",
            "parent_code": "130000000"
        },
        "barangay": {
            "code": "137404009",
            "name": "Bagong Pag-asa",
            "level": "barangay",
            "parent_code": "137404000"
        },
        "street": "123 RIZAL ST"
    },
    "errors": null,
    "meta": []
}
```

#### HTTP 422: Missing or too long address

Response schema: `see openapi.json`

## `GET /api/client/v1/locations/regions`

The first level of the address picker, in PSGC order. No authentication.

**Authentication:** Public

### Parameters

None.

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: Regions

```json
{
    "success": true,
    "message": "Regions retrieved.",
    "data": [
        {
            "code": "130000000",
            "name": "National Capital Region (NCR)",
            "level": "region",
            "parent_code": null
        }
    ],
    "errors": null,
    "meta": []
}
```

## `GET /api/client/v1/locations/{code}/children`

A region's children are its provinces plus any city without a province (all of NCR), so check each item's `level`: `province` leads to its cities/municipalities, `city`/`municipality` leads to barangays. A barangay has no children. Sorted by name. No authentication.

**Authentication:** Public

### Parameters

| Name | Location | Required | Type / allowed values |
|---|---|---:|---|
| `code` | path | yes | string |

### Request body and validation

No JSON request body.

### Responses

#### HTTP 200: The places below

```json
{
    "success": true,
    "message": "Locations retrieved.",
    "data": [
        {
            "code": "137404009",
            "name": "Bagong Pag-asa",
            "level": "barangay",
            "parent_code": "137404000"
        }
    ],
    "errors": null,
    "meta": []
}
```

#### HTTP 404: Unknown code

Response schema: `see openapi.json`

