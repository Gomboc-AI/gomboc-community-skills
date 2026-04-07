---
name: build-rule
description: Build an ORL rule by creating workspace files, writing the rule using tree-sitter AST queries, and testing it. Supports any ORL CLI language ID (see references/orl-supported-languages.md).
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
    language: terraform  # or cloudformation-yaml, bicep, or any ORL ID from ../../references/orl-supported-languages.md
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
docker run gombocai/orl language   # lists all supported language IDs for your image
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

## HCL-Specific Guidance (Terragrunt, Packer, Consul, Vault)

HCL uses the same tree-sitter grammar as Terraform but without Terraform-specific template helpers. Use raw tree-sitter queries.

**Key mechanics:**
- Blocks: `block` nodes with `identifier` for the type and `body` containing attributes
- Attributes: `attribute` nodes with `identifier` (key) and expression (value)
- Function calls: `function_call` nodes with `identifier` (name) and `function_arguments`
- Terragrunt-specific blocks: `include`, `dependency`, `inputs`, `remote_state`, `terraform`
- String templates: `template_expr` containing `template_literal` and `template_interpolation`
- Booleans are unquoted: `true`/`false` (tree-sitter: `literal_value`)

**Example — flag missing encryption in remote_state:**
```yaml
audit: |
  (block
    (identifier) @_block_type
    (body
      (block
        (identifier) @_config_type
        (body) @config_body
      )
    )
  )
  (#eq? @_block_type "remote_state")
  (#eq? @_config_type "config")
skip_finding: |
  finding.config_body matches "encrypt"
remediation:
  - command: insert_after
    path: config_body
    flags:
      indent: "  "
    value: |
      encrypt = true
```

## Dockerfile-Specific Guidance

Dockerfile uses a Dockerfile-specific tree-sitter grammar.

**Key node types:**
- `from_instruction` — `FROM` directives with `image_spec` (name, tag, digest)
- `user_instruction` — `USER` directives
- `run_instruction` — `RUN` commands with `shell_command` or `json_string_array`
- `env_instruction` — `ENV` key=value pairs
- `arg_instruction` — `ARG` build arguments
- `copy_instruction` — `COPY` directives
- `healthcheck_instruction` — `HEALTHCHECK` directives
- `expose_instruction` — `EXPOSE` ports

**Key mechanics:**
- Image tags are inside `image_tag` nodes; digests are `image_digest` nodes
- Multi-stage builds have multiple `from_instruction` nodes — scope rules to the final stage when checking `USER`
- `RUN` commands contain shell text as `shell_fragment` — use `#match?` for pattern detection
- No template helpers — all queries are raw tree-sitter

**Example — flag mutable image tags:**
```yaml
audit: |
  (from_instruction
    (image_spec
      name: (image_name) @_name
      tag: (image_tag) @tag
    )
  )
skip_finding: |
  finding.tag matches "@sha256:"
```

**Example — flag missing USER directive:**
```yaml
audit: |
  (source_file) @root
skip_finding: |
  finding.root matches "USER"
```

## Kubernetes-Specific Guidance

Kubernetes manifests are YAML files with `apiVersion` and `kind` fields. Use raw tree-sitter YAML queries, scoping by resource kind.

**Key mechanics:**
- Kubernetes resources are YAML documents with `apiVersion:` + `kind:` at the top level
- Use `block_mapping_pair` nodes to navigate the YAML structure
- Scope queries with `#eq?` predicates on `kind` values (e.g., `Deployment`, `Pod`, `StatefulSet`)
- Container specs are nested: `spec` → `template` → `spec` → `containers` → list items
- `securityContext` can appear at Pod level or container level
- Use `#match?` on `flow_node` or `plain_scalar` for value checks

**Boolean values:** Kubernetes YAML follows standard YAML boolean rules — `true`/`false` are the canonical forms, but `True`/`TRUE`/`yes`/`Yes`/`on` etc. are also valid. Use `#match?` with a regex for falsy values.

**Example — flag missing runAsNonRoot:**
```yaml
audit: |
  (block_mapping_pair
    key: (flow_node) @_kind_key
    value: (flow_node) @_kind_val
  )
  (#eq? @_kind_key "kind")
  (#eq? @_kind_val "Deployment")
  (block_mapping_pair
    key: (flow_node) @_spec_key
    value: (block_node (block_mapping) @pod_spec)
  )
  (#eq? @_spec_key "spec")
skip_finding: |
  finding.pod_spec matches "runAsNonRoot"
```

**Example — flag missing resource limits:**
```yaml
audit: |
  (block_mapping_pair
    key: (flow_node) @_key
    value: (block_node (block_mapping) @container_spec)
  )
  (#eq? @_key "containers")
skip_finding: |
  finding.container_spec matches "limits"
```

## Python-Specific Guidance

Python uses the Python tree-sitter grammar. Rules can target application code, IaC SDK usage (AWS CDK, Pulumi), and configuration.

**Key node types:**
- `call` — function/method calls with `attribute` or `identifier` as the function and `argument_list` containing `keyword_argument` and positional args
- `import_statement` / `import_from_statement` — imports
- `assignment` — variable assignments with `identifier` (left) and expression (right)
- `string` / `concatenated_string` / `formatted_string` — string literals including f-strings
- `decorated_definition` — functions/classes with decorators
- `class_definition` / `function_definition` — definitions

**Key mechanics:**
- f-strings are `formatted_string` nodes containing `interpolation` children — use these to detect string interpolation in sensitive contexts (SQL, shell)
- Keyword arguments: `keyword_argument` with `identifier` (key) and expression (value) — use to detect `verify=False`, `shell=True`, etc.
- Method chains: `call` → `attribute` → `call` — e.g., `requests.get(url, verify=False)`
- Boolean values: `True`/`False` (capitalized, tree-sitter: `true`/`false` identifiers)
- `None` is a distinct value (tree-sitter: `none`)

**Example — flag verify=False in requests:**
```yaml
audit: |
  (call
    function: (attribute
      object: (identifier) @_module
      attribute: (identifier) @_method
    )
    arguments: (argument_list
      (keyword_argument
        name: (identifier) @_kwarg
        value: (false) @value
      )
    )
  )
  (#eq? @_module "requests")
  (#match? @_method "get|post|put|patch|delete|head|options")
  (#eq? @_kwarg "verify")
remediation:
  - command: replace
    path: value
    value: "True"
```

**Example — flag eval() calls:**
```yaml
audit: |
  (call
    function: (identifier) @_func
    arguments: (argument_list) @args
  ) @eval_call
  (#eq? @_func "eval")
```

**Example — flag hardcoded passwords:**
```yaml
audit: |
  (assignment
    left: (identifier) @_var
    right: (string) @value
  )
  (#match? @_var "(?i)password|secret|api_key|token|credential")
```

## Pre-Completion Checklist

Before declaring the rule complete:
- [ ] `docker run -v "${PWD}:/workspace" gombocai/orl test .` passes with zero failures
- [ ] Every test case from the plan has a corresponding workspace file
- [ ] Workspace files have NO comments
- [ ] All filter-only captures use underscore prefix (`@_name`)
- [ ] `indent` flag used instead of hardcoded spaces in values
- [ ] Rule handles both "wrong value" and "missing attribute" cases (if applicable)
