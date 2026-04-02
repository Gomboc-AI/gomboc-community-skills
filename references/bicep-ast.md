# Bicep AST Reference

Bicep is parsed with its own tree-sitter grammar. This document describes key AST node types used when writing ORL audit queries for Bicep templates.

## Key AST Node Types

| Node Type | Description |
|-----------|-------------|
| `program` | Root node containing top-level statements |
| `resource_declaration` | `resource <id> '<type>@<apiVersion>'` block; the `existing` keyword variant has no `properties` |
| `param_declaration` | Parameter declaration |
| `var_declaration` | Variable declaration |
| `output_declaration` | Output declaration |
| `module_declaration` | Module declaration |
| `decorator` | `@name(...)` nodes above declarations |
| `object` / `object_property` | `{ key: value }` literals |
| `array` | `[item1, item2]` array literals |
| `string` | Plain string; contains `string_content` and optionally `string_interpolation` children for interpolated strings |
| `boolean` | `true` / `false` |
| `null` | Null literal |
| `number` | Numeric literal |
| `identifier` | Bare name reference (parameter, variable, resource symbolic name) |
| `member_expression` | `resource.properties.value` or `obj.key` |
| `call_expression` | Function calls like `uniqueString(...)`, `resourceGroup()` |
| `ternary_expression` | `condition ? trueVal : falseVal` |
| `for_expression` | `[for x in xs: ...]` or `{for k, v in obj: k => v}` |
| `if_condition` | `resource ... = if (cond) { ... }` |

## Resource Declaration Structure

```
resource_declaration
  identifier          // symbolic name (e.g., "storageAccount")
  string              // resource type with API version
    string_content    // e.g., "Microsoft.Storage/storageAccounts@2023-01-01"
  object              // resource body
    object_property   // top-level properties (name, location, sku, properties, etc.)
      identifier      // property key
      ...             // property value (string, object, boolean, etc.)
```

## Key Patterns

### Matching a resource by type
```
(resource_declaration
  (string (string_content) @_type)
  (object ...)
  (#match? @_type "Microsoft\\.Storage/storageAccounts")
)
```

The resource type string includes the API version (e.g., `Microsoft.Storage/storageAccounts@2023-01-01`). Use `#match?` with a prefix pattern to match regardless of API version.

### Matching a property inside `properties`
```
(resource_declaration
  (string (string_content) @_type)
  (object
    (object_property
      (identifier) @_props_key
      (object
        (object_property
          (identifier) @_prop_key
          (boolean) @value
        )
      )
    )
  )
  (#match? @_type "Microsoft\\.Storage/storageAccounts")
  (#eq? @_props_key "properties")
  (#eq? @_prop_key "supportsHttpsTrafficOnly")
  (#eq? @value "false")
)
```

### Insert missing property (Bicep pattern)

Unlike Terraform, Bicep's `object` node includes `{` and `}` braces, so `insert_after` on an `object` places content outside `}`. Use the `replace` + template approach instead:

```yaml
audit: |
  (resource_declaration
    (string (string_content) @_type)
    (object
      (object_property
        (identifier) @_props_key
        (object) @props_body
      )
    )
  ) @resource
  (#match? @_type "Microsoft\\.KeyVault/vaults")
  (#eq? @_props_key "properties")
skip_finding: |
  finding.resource matches "enablePurgeProtection"
remediation:
  - command: replace
    path: props_body
    value: |-
      {
          enablePurgeProtection: true{{ $.props_body | replace("{", "", 1) }}
```

This captures the properties `object`, skips if the property already exists in the resource text, and replaces the object by prepending the new property inside `{...}`.

## Important Differences from Terraform

- **No template helpers**: Bicep does not have `aResource`, `anAttribute`, `aMissingAttribute` helpers. All queries use raw tree-sitter patterns.
- **Object nodes include braces**: The `object` node spans from `{` to `}` inclusive. Use `insert_after` on `object_property` children (not the `object` itself) to insert content inside an object.
- **Boolean values**: Bicep uses lowercase `true`/`false` only (no YAML-style variants like `True`, `yes`, `on`).
- **String literals**: Use single quotes `'...'` not double quotes.
- **API version in type string**: The resource type includes the API version (e.g., `Microsoft.Storage/storageAccounts@2023-01-01`). Strip or ignore the `@version` suffix when matching.
