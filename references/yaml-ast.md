# YAML AST Reference

This reference is based on the Tree-sitter YAML grammar used by ORL. Use this to identify anchor points and values when auditing YAML-based configurations (e.g., Kubernetes, CloudFormation, or ORL itself).

## 1. High-Level Structural Nodes
These nodes define the overall structure of a YAML file.

| Node Type | Description | Notes |
| :--- | :--- | :--- |
| `stream` | The root node of a YAML file. | Contains one or more `document` nodes. |
| `document` | A single YAML document. | Can be explicit (starting with `---`) or implicit. |
| `block_mapping` | A standard YAML map (indentation-based). | Contains `block_mapping_pair` nodes. |
| `block_sequence` | A standard YAML list (indentation-based). | Contains `block_sequence_item` nodes. |

## 2. Mapping & Sequence Nodes
Use these to target keys, values, and list items.

| Node Type | Description | Pattern / Example |
| :--- | :--- | :--- |
| `block_mapping_pair` | A key-value pair in a map. | Uses fields `key` and `value`. |
| `block_sequence_item` | An item in a list starting with `-`. | Contains a `block_node` or `flow_node`. |
| `flow_mapping` | An inline map: `{key: value}`. | Contains `flow_pair` nodes. |
| `flow_sequence` | An inline list: `[item1, item2]`. | Contains `flow_node` nodes. |
| `flow_pair` | A key-value pair inside an inline map. | Uses fields `key` and `value`. |

## 3. Scalar (Value) Nodes
YAML distinguishes between different types of scalar values.

| Node Type | Description | Examples |
| :--- | :--- | :--- |
| `string_scalar` | A plain or quoted string. | `hello`, `"hello"`, `'hello'` |
| `integer_scalar` | A whole number. | `42`, `-1` |
| `float_scalar` | A decimal number. | `3.14`, `1.0e-5` |
| `boolean_scalar` | A truthy/falsy value. | `true`, `false`, `yes`, `no` |
| `null_scalar` | A null value. | `null`, `~`, (empty) |
| `double_quote_scalar` | Specifically a `"..."` string. | `"quoted value"` |
| `single_quote_scalar` | Specifically a `'...'` string. | `'quoted value'` |
| `block_scalar` | A multi-line string. | Literals (`|`) or Folded (`>`). |

## 4. Metadata & Anchors
Nodes for advanced YAML features.

| Node Type | Description | Example |
| :--- | :--- | :--- |
| `anchor` | An anchor definition (`&name`). | `&my_anchor` |
| `alias` | A reference to an anchor (`*name`). | `*my_anchor` |
| `tag` | A type tag (e.g., `!!str`, `!Ref`). | `!Secret`, `!!int` |
| `yaml_directive` | A `%YAML` directive. | `%YAML 1.2` |

---

## Common YAML Query Patterns

### Targeting a Key in a Map
To find a pair where the key is "kind" and the value is "Deployment":
```query
(block_mapping_pair
  key: (flow_node (plain_scalar (string_scalar) @key)) (#eq? @key "kind")
  value: (block_node (plain_scalar (string_scalar) @value)) (#eq? @value "Deployment")
)
```

### Navigating Nested Maps
To find a specific nested key (e.g., `spec.replicas`):
```query
(block_mapping_pair
  key: (_) @k1 (#eq? @k1 "spec")
  value: (block_node
    (block_mapping
      (block_mapping_pair
        key: (_) @k2 (#eq? @k2 "replicas")
        value: (_) @replicas
      )
    )
  )
)
```

### Finding a Specific Item in a Sequence
```query
(block_sequence
  (block_sequence_item
    (block_node (plain_scalar (string_scalar) @item)) (#eq? @item "my-item")
  )
)
```

### Targeting Tags (e.g., CloudFormation Functions)
```query
(flow_node
  (tag) @tag (#eq? @tag "!Ref")
  (plain_scalar) @value
)
```

## Remediation Paths (YAML Specific)
- `path: value` targets the value side of a pair (the node after the `:`).
- `path: key` targets the key side of a pair.
- `path: block_mapping_pair` targets the entire `key: value` line.
- `path: block_sequence_item` targets the entire line starting with `-`.

---

## Common Helper Patterns (Pseudo-Helpers)

Unlike Terraform, YAML doesn't have pre-built string helpers, but you can use these standard patterns:

### Find a Resource by Type (e.g., K8s or CloudFormation)
```query
(block_mapping
  (block_mapping_pair
    key: (_) @k (#match? @k "(Type|kind)")
    value: (_) @type (#eq? @type "AWS::S3::Bucket")
  )
) @resource
```

### Find an Attribute (Property) by Name
```query
(block_mapping_pair
  key: (_) @name (#eq? @name "PublicAccessBlockConfiguration")
  value: (_) @value
) @attribute
```

---

## CloudFormation Specifics

CloudFormation uses intrinsic functions that appear as tags or special mapping keys.

### Targeting Intrinsic Functions (e.g., !Ref)
```query
(flow_node
  (tag) @tag (#eq? @tag "!Ref")
  (plain_scalar) @value
)
```

### Targeting "Fn::" Functions
```query
(block_mapping_pair
  key: (_) @fn (#match? @fn "Fn::.*")
  value: (_) @args
)
```

### Remediation in Lists
When adding a property to a CloudFormation resource's `Properties` section:
1.  Target the `Properties` key's `value`.
2.  Use `insert_after` or `insert_before`.

---

## The "Missing" Logic Problem

**CRITICAL:** Tree-Sitter queries are for finding things that *exist*. For YAML, use the **AST key enumeration pattern** — it is the direct equivalent of Terraform's `aMissingAttribute` and is the preferred approach:

```orl
(block_mapping_pair
  (flow_node) @_properties_key
  (block_node
    (block_mapping
      [
        (block_mapping_pair
          (flow_node) @key
          (_)
        )
        (comment)
      ]*
      (#not-eq? @key "PropertyName")
    )
  ) @properties
  (#eq? @_properties_key "Properties")
)
```

This captures each key `flow_node` in the Properties block and asserts none equals `"PropertyName"`. Because it matches **AST key nodes only**, it is not fooled by:
- The property name appearing in a string value (value nodes are not captured by `@key`)
- The property name being commented out (`(comment)` is matched as an alternative but does not capture `@key`, so commented-out keys are invisible to the predicate)

**Fallback: line-anchored `#not-match?`** — use this only when the AST pattern is impractical (e.g., the key could be a non-plain scalar):

```orl
(#not-match? @properties "(?m)^[ \t]*PropertyName:")
```

The line-anchor `(?m)^[ \t]*` prevents matching comments (`# PropertyName:`) and string values, since those never start a YAML line with only whitespace followed by the key.

**Avoid bare text search**: `(#not-match? @properties "PropertyName:")` or `hasSubString(finding.body, "PropertyName:")` — both produce false negatives for commented-out properties because YAML comment nodes are children of the `block_mapping` and their text is included in the captured node.
3.  Ensure the `indent` flag matches the parent's indentation (usually `      ` for CloudFormation).
