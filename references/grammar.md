# ORL Formal Grammars

ORL is a multi-layered language. While the top-level structure is YAML, the "logic" of ORL is defined by several embedded sub-languages. This document outlines the formal grammars that govern these sub-languages.

- [ORL Formal Grammars](#orl-formal-grammars)
  - [Top-Level Structure (YAML)](#top-level-structure-yaml)
  - [The Audit Query Language (`orl-query`)](#the-audit-query-language-orl-query)
    - [Key Features](#key-features-1)
    - [Used In](#used-in-1)
  - [The Expression Language (`orl-expr`)](#the-expression-language-orl-expr)
    - [Key Features](#key-features)
    - [Used In](#used-in)
  - [Templating (The Bridge)](#templating-the-bridge)
    - [Grammar Injections](#grammar-injections)

## Top-Level Structure (YAML)

The overall file format of an `.orl` file is YAML. ORL uses standard YAML parsing for the high-level keys like `type`, `metadata`, and `spec`. The formal structure of these keys is defined by the [JSON Schemas](../schema/).

## The Audit Query Language (`orl-query`)

When `audit_language` is set to `ast`, ORL uses a specialized version of the **Tree-sitter Query Language**.

### Key Features
- **S-Expressions:** Uses Lisp-like `(node_type ...)` syntax to traverse the AST.
- **Captures:** Uses the `@` symbol to name nodes for later remediation (e.g., `(identifier) @my_capture`).
- **Predicates:** Uses `#` commands for complex filtering (e.g., `(#eq? @my_capture "forbidden_value")`).
- **Template Injections:** Unlike standard Tree-sitter queries, ORL queries can contain `{{ orl-expr }}` blocks to dynamically build queries based on variables.

### Used In
- `spec.audit`
- `spec.collect[].audit`

## The Expression Language (`orl-expr`)

The core logic of ORL is driven by an expression language based on [expr-lang](https://github.com/expr-lang/expr). 

### Key Features
- **Operators:** Standard arithmetic (`+`, `-`, `*`, `/`), logical (`&&`, `||`, `!`, `not`), and comparison (`==`, `!=`, `<`, `>`, `contains`, `matches`, `in`).
- **Pipes:** Supports the pipe operator (`|`) for functional transformations (e.g., `{{ finding.name | upper() }}`).
- **Null Safety:** Includes null-coalescing (`??`) and optional chaining (`?.`) to handle missing data gracefully.
- **ORL Identifiers:** First-class support for ORL-specific objects:
    - `$`, `finding`: The current finding being remediated.
    - `vars`: Access to variable contexts.
    - `collections`: Access to cross-file data collections.
    - `item`: The current item in a `foreach` loop.

### Used In
- `spec.skip_finding`
- `spec.foreach`
- `spec.remediation[].skip`
- Inside `{{ ... }}` blocks in any string field.

## Templating (The Bridge)

ORL uses a "bridge" approach to connect YAML to its sub-languages. 

### Grammar Injections
When using the ORL Language Server or VS Code extension, the system performs **Grammar Injections** based on the YAML key:

1.  **Direct Injections:** Fields like `skip_finding` are treated entirely as `orl-expr`.
2.  **String Injections:** In fields like `remediation[].value`, the parser looks for `{{` and `}}` markers. The content between these markers is "injected" with the `orl-expr` grammar, while the surrounding text is treated as a literal string.
3.  **Nested Injections:** If an `orl-expr` block is found inside an `audit` query, the parser handles it as a nested injection (`YAML` -> `orl-query` -> `orl-expr`).

This multi-grammar approach allows ORL to provide deep intelligence (like autocomplete and type checking) even inside complex YAML strings.
