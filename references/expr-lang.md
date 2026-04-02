# ORL Expression Language (orl-expr) Reference

ORL uses a powerful expression language based on [Expr](https://expr-lang.org/) for logic, filtering, and dynamic value generation. This language is used in `skip_finding`, `remediation[].skip`, `remediation[].value`, and inside `{{ ... }}` blocks.

## 1. Core Syntax & Operators

### Arithmetic & Comparison
*   **Arithmetic**: `+`, `-`, `*`, `/`, `%`, `**` (exponent)
*   **Comparison**: `==`, `!=`, `<`, `>`, `<=`, `>=`
*   **Logical**: `&&`, `||`, `!`, `not`
*   **Membership**: `in`, `not in`, `contains`, `matches` (regex)

### Functional Pipes
The pipe operator (`|`) allows for chaining transformations:
`{{ finding.name | upper() | trimPrefix("AWS_") }}`

### Null Safety
*   **Optional Chaining**: `finding.attributes?.public_access` (returns `nil` if `attributes` is missing)
*   **Null Coalescing**: `finding.value ?? "default_value"` (returns "default_value" if `finding.value` is `nil`)

---

## 2. Access Patterns (Root Objects)

| Object | Description |
| :--- | :--- |
| `$`, `finding` | The current finding being processed. Contains captured nodes. |
| `vars` | Access to variable contexts defined in `spec.variables`. |
| `collections` | Data collected across the workspace via `spec.collect`. |
| `item` | The current element when inside a `foreach` loop. |

### Accessing Captures
If your audit query has `(identifier) @name`, access it via:
`{{ $.name }}` or `{{ finding.name }}`

---

## 3. Custom ORL Functions
These functions are specifically added to ORL to simplify source code auditing.

### `collect(root, path)`
Traverses an object (usually `collections`) to find values.
`{{ collect(collections, "engine.*.value") }}` -> `["mysql", "postgres"]`

### `semVerCmp(v1, operator, v2)`
Compares semantic version strings.
`{{ semVerCmp("1.2.3", ">", "1.1.0") }}` -> `true`

### `hasSubString(target, search)`
Checks if `search` exists in `target` (string or array of strings).
`{{ ["prod", "dev"] | hasSubString("prod") }}` -> `true`

---

## 4. Built-in Functions (Expr)

### String Functions
*   **`trim(str[, chars])`**: Removes whitespace or specified chars.
*   **`upper(str)`** / **`lower(str)`**: Case conversion.
*   **`replace(str, old, new)`**: Substring replacement.
*   **`split(str, sep)`**: Returns an array of strings.
*   **`hasPrefix(str, pre)`** / **`hasSuffix(str, suf)`**: Prefix/suffix check.

### Array & Collection Functions
*   **`all(array, predicate)`**: True if all satisfy the condition.
*   **`any(array, predicate)`**: True if any satisfy the condition.
*   **`filter(array, predicate)`**: Returns a subset of the array.
*   **`map(array, predicate)`**: Transforms each element.
*   **`count(array[, predicate])`**: Counts matches.
*   **`first(array)`** / **`last(array)`**: Returns the first/last element.
*   **`flatten(array)`**: Flattens nested arrays.
*   **`uniq(array)`**: Removes duplicates.

**Predicate Syntax**: Use `#` to refer to the current element in predicates.
`{{ filter(my_array, { # > 10 }) }}`

### Number Functions
*   **`max(a, b)`**, **`min(a, b)`**, **`abs(n)`**
*   **`ceil(n)`**, **`floor(n)`**, **`round(n)`**

### Type Conversion
*   **`int(v)`**, **`float(v)`**, **`string(v)`**
*   **`toJSON(v)`**, **`fromJSON(str)`**
*   **`type(v)`**: Returns "int", "string", "map", etc.

### Miscellaneous
*   **`len(v)`**: Length of string, array, or map.
*   **`get(v, key)`**: Safe access to maps or arrays.

---

## 5. Practical Examples & Recipes

### Cross-Resource Data Lookups
Use this pattern to find an attribute of the *current* resource that was captured in a separate `collect` block.

```orl
# Look up the 'engine' attribute for the resource currently being audited
let engine = trim(
  first(
    filter(
      flatten(collect(collections, "engine.*")), 
      { #.name == finding.name }
    )
  )?.value ?? "\"\"", 
  "\""
)
```

### Complex Conditional Auditing
Use nested `if` statements in `skip_finding` to implement complex logic like RDS log requirements.

```orl
# skip_finding: Skip if logs are correctly set based on engine type
let is_valid = if hasSubString(lower(engine), "mysql") {
  hasSubString($.value, "audit") && hasSubString($.value, "error")
} else if hasSubString(lower(engine), "postgres") {
  hasSubString($.value, "postgresql")
} else {
  false
};

engine_unsupported or is_valid
```

### Dynamic List Generation
Build HCL list strings dynamically using `join` and `if` logic.

```orl
# remediation.value: Generate a list of logs based on engine and IAM status
{{ 
  let logs = ["\"error\"", "\"audit\""];
  if iam_enabled {
    let logs = logs + ["\"iam-db-auth-error\""];
  }
  "[" + join(logs, ", ") + "]"
}}
```

### Variable-Driven Remediation
Only apply a remediation if a specific variable is defined in the context.

```orl
# remediation.skip: Skip if no default KMS key is provided
vars.default?.kms_key_id == nil

# remediation.value: Use the variable
{{ vars.default.kms_key_id }}
```

### Checking for "Anti-Patterns" in Finding Body
Use `hasSubString` on the raw `finding.body` to skip findings based on the presence of other attributes not easily captured by the AST.

```orl
# skip_finding: Don't require encryption if the volume is created from a snapshot
hasSubString(finding.body, "snapshot_id")
```
