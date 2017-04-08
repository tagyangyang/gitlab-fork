# Build Variables

## List project variables

Get list of a project's build variables.

```
GET /projects/:id/variables
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string | yes      | The ID of a project or [urlencoded NAMESPACE/PROJECT_NAME of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/variables"
```

```json
[
    {
        "key": "TEST_VARIABLE_1",
        "value": "TEST_1"
    },
    {
        "key": "TEST_VARIABLE_2",
        "value": "TEST_2"
    }
]
```

## Show variable details

Get the details of a project's specific build variable.

```
GET /projects/:id/variables/:key
```

| Attribute | Type    | required | Description           |
|-----------|---------|----------|-----------------------|
| `id`      | integer/string | yes      | The ID of a project or [urlencoded NAMESPACE/PROJECT_NAME of the project](README.md#namespaced-path-encoding) owned by the authenticated user   |
| `key`     | string  | yes      | The `key` of a variable |

```
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/variables/TEST_VARIABLE_1"
```

```json
{
    "key": "TEST_VARIABLE_1",
    "value": "TEST_1"
}
```

## Create variable

Create a new build variable.

```
POST /projects/:id/variables
```

| Attribute | Type    | required | Description           |
|-----------|---------|----------|-----------------------|
| `id`      | integer/string | yes      | The ID of a project or [urlencoded NAMESPACE/PROJECT_NAME of the project](README.md#namespaced-path-encoding) owned by the authenticated user   |
| `key`     | string  | yes      | The `key` of a variable; must have no more than 255 characters; only `A-Z`, `a-z`, `0-9`, and `_` are allowed |
| `value`   | string  | yes      | The `value` of a variable |

```
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/variables" --form "key=NEW_VARIABLE" --form "value=new value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "new value"
}
```

## Update variable

Update a project's build variable.

```
PUT /projects/:id/variables/:key
```

| Attribute | Type    | required | Description             |
|-----------|---------|----------|-------------------------|
| `id`      | integer/string | yes      | The ID of a project or [urlencoded NAMESPACE/PROJECT_NAME of the project](README.md#namespaced-path-encoding) owned by the authenticated user     |
| `key`     | string  | yes      | The `key` of a variable   |
| `value`   | string  | yes      | The `value` of a variable |

```
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/variables/NEW_VARIABLE" --form "value=updated value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value"
}
```

## Remove variable

Remove a project's build variable.

```
DELETE /projects/:id/variables/:key
```

| Attribute | Type    | required | Description             |
|-----------|---------|----------|-------------------------|
| `id`      | integer/string | yes      | The ID of a project or [urlencoded NAMESPACE/PROJECT_NAME of the project](README.md#namespaced-path-encoding) owned by the authenticated user     |
| `key`     | string  | yes      | The `key` of a variable |

```
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/1/variables/VARIABLE_1"
```
