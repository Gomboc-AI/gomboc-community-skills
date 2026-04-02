# ORL AST General Reference

When `audit_language` is set to `ast`, ORL uses Tree-sitter queries to identify code patterns for remediation. This guide explains the language-agnostic principles for writing effective AST queries and remediations across the 30+ languages ORL supports.

## 1. The Core Workflow: Audit -> Capture -> Remediate
An AST query has two primary jobs:
1.  **Filter**: Use node types and predicates (`#eq?`, `#match?`) to find code that violates a policy.
2.  **Capture**: Use the `@` symbol to name specific nodes that the `remediation` commands will operate on.

### Conventions for Captures
*   **Remediation Captures**: Captures intended for use in the `path` field of a remediation command should be named clearly (e.g., `@body`, `@value`, `@attribute`).
*   **Filter-Only Captures**: Captures used *only* for predicates should be prefixed with an underscore (e.g., `@_type`, `@_keyword`). These are not available for remediation, which prevents "cluttering" the remediation context and avoids accidental replacements.

## 2. Common Query Patterns

### Filtering by Node Content
Use predicates to refine your search. For example, to find a variable declaration but only if its name is "secret":
```query
(variable_declaration
  (identifier) @name (#eq? @name "secret")
) @variable
```

### Negated Matches
To find a node that *lacks* a specific child (e.g., a function with no parameters):
```query
(function_definition
  !parameters
) @function
```

### Quantifiers
*   `*`: Zero or more.
*   `+`: One or more.
*   `?`: Optional.

## 3. Remediating Captured Nodes
When you define a `remediation` step, the `path` field points to one of your `@captures`.

| Command | Path Use Case |
| :--- | :--- |
| `replace` | Point to the node you want to completely overwrite with the `value`. |
| `insert_after` | Point to the node that the new code should follow. |
| `remove` | Point to the node you want to delete. |

## 4. Discovering Nodes for New Languages
Since ORL supports 37+ languages, you may not know the node types for a specific language (e.g., Kotlin or Rust). Use the `orl walk` command to inspect the AST of a sample file:

```bash
docker run -v "${PWD}:/workspace" gombocai/orl walk <filename> --language <language_name>
```

This will output the tree structure, showing you exactly which node types and field names to use in your query.

## 5. Best Practices
1.  **Be Surgical**: Capture the smallest possible node for the change you want to make. If you only want to change a value, capture the `@value` node, not the entire `@attribute`.
2.  **Use Predicates for Flexibility**: Don't rely on exact node nesting if a predicate can do the job. This makes your rules more robust to formatting changes.
3.  **Template Your Queries**: You can use `{{ }}` blocks within your queries to inject dynamic values from `vars` or `collections`.
