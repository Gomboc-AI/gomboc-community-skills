---
name: build-rule
description: Build an ORL rule by creating workspace files, writing the rule using tree-sitter AST queries, and testing it. Supports Terraform, CloudFormation YAML, and Bicep with embedded language expertise.
---

# Build an ORL Rule

You are an expert ORL rule builder. You create ORL rules that audit and remediate Infrastructure as Code using tree-sitter AST queries. Consult the reference docs in `../../references/` for ORL syntax, grammar, and language-specific AST patterns.

## ORL via Docker

ORL is distributed as a Docker image. All `orl` commands MUST be run via Docker, mounting the current working directory into `/workspace`:

```bash
docker run -v "${PWD}:/workspace" gombocai/orl <command> [args...]
```

Throughout this skill, every `orl` command shown follows this pattern.

## Key References

- **ORL quick reference**: `../../references/orl-docs.md`
- **ORL grammar**: `../../references/grammar.md`
- **Expression language**: `../../references/expr-lang.md`
- **Terraform AST helpers**: `../../references/hcl-ast.md`
- **CloudFormation YAML AST**: `../../references/yaml-ast.md`
- **Bicep AST**: `../../references/bicep-ast.md`
- **Examples**: `../../references/examples/{terraform,cloudformation,bicep}/`

## Development Process

### 1. Create Workspace Files

Create the rule directory with test files:

```
my-rule/
├── workspace/          # IaC files WITH violations
├── workspace_expected/ # IaC files AFTER remediation
├── my-rule.orl         # The rule (written in step 3)
└── test.orl            # Test definition (written in step 4)
```

**Important**: NO COMMENTS in workspace files. Comments break diff-based testing.

### 2. Explore the AST

Use the ORL `walk` command to visualize the AST structure of your workspace files. Run from the rule directory:

```bash
docker run -v "${PWD}:/workspace" gombocai/orl walk workspace --language terraform ./workspace
docker run -v "${PWD}:/workspace" gombocai/orl walk workspace --language cloudformation-yaml ./workspace
docker run -v "${PWD}:/workspace" gombocai/orl walk workspace --language bicep ./workspace
```

This shows the exact tree-sitter node types and structure you need to match in your audit query.

### 3. Write the ORL Rule

Use the rule template from `../../assets/templates/`. A rule has this structure:

```yaml
type: Ruleset
version: v1
metadata:
  name: gomboc-ai/my-rule-name
  classifications:
    - gomboc-ai/policy/...
spec:
  template:
    language: terraform  # or cloudformation-yaml, bicep
    audit_language: ast
  rules:
    - name: descriptive-rule-name
      audit: |
        <tree-sitter query>
      remediation:
        - command: replace|insert_after|insert_before|remove
          path: <capture-name>
          value: "<new value>"
```

### 4. Write the Test File

```yaml
type: Test
version: v1
metadata:
  name: my-rule-test
spec:
  rulespace: "."
  cases:
    - name: Descriptive Test Name
      language: terraform
      workspace:
        path: ./workspace
      remediated_workspace:
        path: ./workspace_expected
      expected_report:
        errors: []
```

**Critical**: Use `mode: ast` if specified. NEVER use `comparison: ast` — that key is invalid.

### 5. Test and Debug

Run from the rule directory:

```bash
# Run tests
docker run -v "${PWD}:/workspace" gombocai/orl test .

# Dry-run remediation to see actual output
docker run -v "${PWD}:/workspace" gombocai/orl remediate -d --language terraform -r . ./workspace
```

If tests fail, compare actual vs expected output and adjust the rule or expected files.

### 6. Check available template functions

```bash
docker run gombocai/orl language terraform
docker run gombocai/orl language cloudformation-yaml
docker run gombocai/orl language bicep
```

## Critical Best Practices

1. **AST, not text**: Use tree-sitter structure queries, never bare `hasSubString` for detecting properties
2. **Underscore prefix for filters**: Captures used only for filtering MUST start with `_` (e.g., `@_type`). Only captures used in remediation should be non-underscore
3. **Use `indent` flag**: Never hardcode spaces in `value`. Use `flags: { indent: "  " }` instead
4. **YAML block scalars**: Use `|` (literal block) for code injection, not `|-` or quotes
5. **One rule per pattern**: Separate rules for "wrong value" vs "missing attribute"
6. **Test.orl must use `mode: ast`** if applicable — NOT `comparison: ast`
7. **No comments in workspace files**: They break diff-based testing
8. **Sequential replace + insert_after**: These may conflict on the same node. Combine into a single `replace` if needed
9. **Capture broadly, filter with predicates**: Match wide, then use `#eq?`, `#not-eq?`, `#match?` to narrow

## Terraform-Specific Guidance

Terraform has rich template helpers. Always prefer these over raw queries:

- `aResource("type", ...)` — Match a resource by type
- `anAttribute("key")` — Match an attribute by name
- `anAttributeValueEq("key", "value")` — Match attribute with specific value
- `anAttributeValueNotEq("key", "value")` — Match attribute NOT equal to value
- `aMissingAttribute("key")` — Match resource missing an attribute
- `aBlock("name")` — Match a block by name
- `aMissingBlock("name")` — Match missing block

**Key mechanics:**
- Variables/locals produce `identifier` nodes (not `string_lit`). Rules must handle both forms
- Booleans are unquoted: `true`/`false` (tree-sitter: `literal_value`)
- `count`/`for_each` produce multiple instances — rules still apply per-resource
- Dynamic blocks use a different AST structure than static blocks

## CloudFormation YAML-Specific Guidance

CloudFormation uses raw tree-sitter YAML queries. No template helpers available.

**Key mechanics:**
- Boolean values have 18+ variants: `true`, `True`, `TRUE`, `yes`, `Yes`, `YES`, `on`, `On`, `ON`, `y`, `Y`, `1`, plus quoted forms (`"true"`, `'true"`, etc.)
- Use `#match?` with a regex for falsy values: `^(false|False|FALSE|no|No|NO|off|Off|OFF|n|N|0|"false"|'false')$`
- Intrinsic functions have two forms: `!Ref` (short) vs `Ref:` (long)
- Property absence and `AWS::NoValue` are different
- Resources are under `Resources:` section key in the YAML

**AST structure**: `block_mapping_pair` → `flow_node` (key) + `block_node` (value)

## Bicep-Specific Guidance

Bicep uses raw tree-sitter queries. No template helpers available.

**Key mechanics:**
- Resource type includes API version: `'Microsoft.Storage/storageAccounts@2023-01-01'`
- Use `#match?` on `string_content` to match type regardless of API version
- Booleans are only `true`/`false` (no YAML-style variants)
- Strings use single quotes: `'value'`
- Properties go inside `properties: { ... }` block
- `existing` keyword resources have no properties to remediate
- `insert_after` on an `object` node inserts AFTER the `}` — use `insert_after` on the last `object_property` instead, or use `replace` with template interpolation

**Bicep insert pattern** for missing properties:
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
  (#match? @_type "Microsoft\\.Storage/storageAccounts")
  (#eq? @_props_key "properties")
skip_finding: |
  finding.resource matches "targetPropertyName"
remediation:
  - command: replace
    path: props_body
    value: |-
      {
          targetPropertyName: true{{ $.props_body | replace("{", "", 1) }}
```

## Pre-Completion Checklist

Before declaring the rule complete:
- [ ] `docker run -v "${PWD}:/workspace" gombocai/orl test .` passes with zero failures
- [ ] Every test case from the plan has a corresponding workspace file
- [ ] Workspace files have NO comments
- [ ] All filter-only captures use underscore prefix (`@_name`)
- [ ] `indent` flag used instead of hardcoded spaces in values
- [ ] Rule handles both "wrong value" and "missing attribute" cases (if applicable)
