# HCL / Terraform AST Reference

This reference defines the node types and structures for HCL/Terraform, the most common language targeted by ORL. Use this to identify anchor points and values for your queries.

## 1. High-Level Structural Nodes
These are the primary containers for Terraform code.

| Node Type | Description | Example / Structure |
| :--- | :--- | :--- |
| `source_file` | The root of the HCL document. | Always contains a `body`. |
| `body` | A collection of attributes and blocks. | Found at the root or inside `{}`. |
| `block` | A top-level or nested block (e.g., `resource`, `module`). | `resource "type" "name" { ... }` |
| `attribute` | A key-value pair assignment. | `bucket = "my-bucket"` |
| `one_line_block` | A block defined on a single line. | `network_interface { device_index = 0 }` |

## 2. Attribute & Expression Nodes
Use these to target specific values or types of assignments.

| Node Type | Description | Notes |
| :--- | :--- | :--- |
| `identifier` | The name of an attribute or block type. | Matches `bucket`, `engine`, `aws_instance`. |
| `expression` | The right-hand side of an assignment. | Container for literals, operations, or collections. |
| `literal_value` | Primitives: `true`, `false`, `null`, `numeric_literal`. | Use `#eq? @val "true"` in predicates. |
| `string_literal` | A quoted string (e.g., `"us-east-1"`). | Use `(string_literal) @str`. |
| `collection_value` | A complex type: `tuple` or `object`. | Matches `[...]` or `{...}`. |

## 3. Collection & Nested Nodes
Essential for auditing lists and maps.

| Node Type | Description | Pattern / Example |
| :--- | :--- | :--- |
| `tuple` | A list of expressions (HCL list). | `[ "a", "b", 1 ]` |
| `object` | A map-like structure of key-value pairs. | `{ key = "value" }` |
| `object_elem` | An individual element inside an `object`. | `key = "value"` or `key: "value"` |
| `index` | Accessing a collection by index. | `var.list[0]` |
| `get_attr` | Accessing an attribute on an object. | `aws_s3_bucket.example.id` |

---

## Common HCL Query Patterns

### Targeting a Specific Resource Type
```query
(block
  (identifier) @_type (#eq? @_type "resource")
  (identifier) @_res  (#eq? @_res "aws_db_instance")
  (body) @body
)
```

### Finding an Attribute by Name
```query
(attribute
  (identifier) @name (#eq? @name "publicly_accessible")
  (expression) @value
)
```

### Matching Explicit Literals
```query
(attribute
  (identifier) @name (#eq? @name "iam_database_authentication_enabled")
  (expression 
    (literal_value) @val (#eq? @val "false")
  )
)
```

## Remediation Paths (HCL Specific)
When defining `remediation` in your ORL file for Terraform:
- `path: body` targets the entire content between `{}` in a block.
- `path: value` targets the expression on the right-hand side of an `=`.
- `path: attribute` targets the entire line `key = value`.
- `path: block` targets the entire block from the identifier to the closing `}`.

## Query Helpers

The following are terraform query helpers. They render common AST query strings. Make sure you ONLY use these specific helpers, and no others - you will get errors otherwise. These are very helpful for writing audit queries which need to be able to find specific attributes or resources in Terraform.

```go
// terraformQueries is a map of query name to query string.
// terraformQueryGenerator turns them into
var terraformQueries = map[string]terraformQuery{
	"allResources": {
		query: `(block
  (identifier) @keyword
    (#eq? @keyword "resource")
  (string_lit
    (template_literal) @type
  )
  (string_lit
    (template_literal) @name
  )
  (body
  ) @body
) @resource`,
		minArgs:     0,
		maxArgs:     0,
		description: "Checks for all resources.  'keyword', 'type', 'name', and 'body' are captured.",
	},
	"aResource": {
		query: `(block
  (identifier) @keyword
	(#eq? @keyword "resource")
  (string_lit
    (template_literal) @type
	(#eq? @type "%s")
  )
  (string_lit
    (template_literal) @name
  )
  (body
	%s
  ) @body
) @resource`,
		minArgs:     1,
		maxArgs:     2,
		description: "Checks for a resource with the given type. The optional second argument is an s-expression that is used to match the resource body.  'type', 'name', 'body', and 'resource' are captured.",
	},
	"aModule": {
		query: `(block
  (identifier) @keyword
	(#eq? @keyword "module")
  (string_lit
    (template_literal) @name
	(#eq? @name "%s")
  )
  (body
	%s
  ) @body
) @module`,
		minArgs:     1,
		maxArgs:     2,
		description: "Checks for a module with the given name. The optional second argument is an s-expression that is used to match the module body.  'name', 'body', and 'module' are captured.",
	},
	"aModuleWithSource": {
		query: `(block
  (identifier) @keyword
	(#eq? @keyword "module")
  (string_lit
    (template_literal) @name
  )
  (body
  	(attribute
		(identifier) @source_key
			(#eq? @source_key "source")
		(expression) @source_value
			(#eq? @source_value "\"%s\"")
	) @source
	 %s
  ) @body
) @module`,
		minArgs:     1,
		maxArgs:     2,
		description: "Checks for a module with the given name and source. The optional second argument is an s-expression that is used to match the module body.  'name', 'source_key', 'source_value', 'body', and 'module' are captured.",
	},
	"anAttribute": {
		query: `(attribute
	(identifier) @key
		(#eq? @key "%s")
	(expression) @value
) @attribute`,
		minArgs:     1,
		maxArgs:     1,
		description: "Checks for an attribute with the given name. 'key', 'value', and 'attribute' are captured.",
	},
	"anAttributeValue": {
		query: `(attribute
	(identifier) @key
		(#eq? @key "%s")
	(expression) @value
		%s
) @attribute`,
		minArgs:     2,
		maxArgs:     2,
		description: "Checks for an attribute with the given name.  The second argument is an s-expression that is used to match the attribute value. 'key', 'value', and 'attribute' are captured.",
	},
	"anStringAttributeValue": {
		query: `(attribute
	(identifier) @key
		(#eq? @key "%s")
	(expression
		(literal_value
			(string_lit
				(template_literal) @value
			)
	)
		%s
) @attribute`,
		minArgs:     1,
		maxArgs:     2,
		description: "Checks for an attribute with the given name whose expression is a string that equals the given value. 'key', 'value', and 'attribute' are captured.",
	},
	"anAttributeValueEq": {
		query: `(attribute
		(identifier) @key
			(#eq? @key "%s")
		(expression) @value
			(#eq? @value %s)
	) @attribute`,
		minArgs:     2,
		maxArgs:     2,
		description: "Checks for an attribute with the given name whose expression equals the given value. 'key', 'value', and 'attribute' are captured.",
	},
	"anAttributeValueNotEq": {
		query: `(attribute
		(identifier) @key
			(#eq? @key "%s")
		(expression) @value
			(#not-eq? @value %s)
	) @attribute`,
		minArgs:     2,
		maxArgs:     2,
		description: "Checks for an attribute with the given name whose expression does not equal the given value. 'key', 'value', and 'attribute' are captured.",
	},
	"aMissingAttribute": {
		query: `[
	(attribute
	(identifier)* @key
	) @attribute
	(block)
	(comment)
]*
(#not-eq? @key "%s")`,
		minArgs:     1,
		maxArgs:     1,
		description: "Checks for a missing attribute with the given name. 'key', and 'attribute' are captured. Uses AST-based matching: only fires when no attribute identifier in the body equals the target name. Correctly handles attribute names that appear in string values or comments (comments are siblings of the body node in HCL, not children). Edge case: does not fire on completely empty resource bodies (no 'body' AST node exists for '{}'). Prefer this over text-based approaches for Terraform rules.",
	},
	"aBlock": {
		query: `(block
(identifier) @block_name
	(#eq? @block_name "%s")
(body
	%s
) @block_body
) @block`,
		minArgs:     1,
		maxArgs:     2,
		description: "Checks for a block with the given name. 'block_name', 'block_body', and 'block' are captured.",
	},
	"aDynamicBlock": {
		query: `(block
  (identifier) @keyword (#eq? @keyword "dynamic")
  (string_lit (template_literal) @block_name (#eq? @block_name "%s"))
  (body
    (block
      (identifier) @content_keyword (#eq? @content_keyword "content")
      (body %s) @block_body
    )
  )
) @block`,
		minArgs:     1,
		maxArgs:     2,
		description: "Checks for a dynamic block with the given name. 'block_name', 'block_body', and 'block' are captured.",
	},
	"aSubBlock": {
...
---

## Deep Nesting Patterns

When targeting attributes inside sub-blocks, combine `aResource`, `aBlock`, and `anAttribute`.

```orl
# Target 'encrypted' inside 'ebs_block_device' of 'aws_instance'
{{ aResource("aws_instance", aBlock("ebs_block_device", anAttribute("encrypted"))) }}
```

### Handling Multiple Occurrences
If a block can appear multiple times (like `ebs_block_device`), ORL will find *all* instances. Use `skip_finding` to narrow down which specific instance you want to remediate if you cannot distinguish them via AST queries alone.

### The "Missing" Logic Problem
**CRITICAL:** Tree-Sitter queries are for finding things that *exist*. For Terraform, use `aMissingAttribute` — it is AST-based and is the preferred approach:
1. Use `{{ aResource("aws_resource_type", aMissingAttribute("attribute_name")) }}` to find resources missing the attribute.
2. Use `insert_after` with `path: body` to add the missing content.

`aMissingAttribute` is correct in all common cases. It is not fooled by the attribute name appearing in string values or comments (HCL comments are siblings of the `body` node, not children, so they are never in `finding.body`). The only edge case it misses is a completely empty resource body `{}` — a rare pattern in real Terraform that can be covered with a separate rule if needed.

Avoid `hasSubString(finding.body, "attribute_name")` for Terraform missing-attribute detection: it is equivalent to a bare text search and will produce false negatives when the attribute name appears as a string value in another attribute.
		query: `(block
(identifier) @sub_block_name
	(#eq? @sub_block_name "%s")
(body
	%s
) @sub_block_body
) @sub_block`,
		minArgs:     1,
		maxArgs:     2,
		description: "Checks for a sub-block with the given name. 'sub_block_name', 'sub_block_body', and 'sub_block' are captured.",
	},
	"aMissingBlock": {
		query: `[
	(block
	(identifier)* @block_name
	) @block
	(attribute)
	(comment)
]*
(#not-eq? @block_name "%s")`,
		minArgs:     1,
		maxArgs:     1,
		description: "Checks for a missing block with the given name. 'block_name', and 'block' are captured.",
	},
	"anEmptyBlock": {
		query: `
  (block
    (identifier) @block_name
    (block_start)
	[(body) @block_body
     (comment)*
    ]
	(block_end) @block_end
  )
  (#eq? @block_body "")
  (#eq? @block_name "%s")`,
		minArgs:     1,
		maxArgs:     1,
		description: "Checks for an empty block with the given name. 'block_name', 'block_body', and 'block_end' are captured.",
	},
}

type terraformQuery struct {
	query       string
	minArgs     int
	maxArgs     int
	description string
}
```