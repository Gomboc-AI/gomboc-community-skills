---
name: apply-fix
description: Apply a fix to source code using an existing ORL rule or by generating a new one. Supports Terraform, HCL/Terragrunt, CloudFormation (YAML + JSON), Bicep, Dockerfile, Kubernetes, and Python. Optionally saves the fix as a reusable, publishable ORL rule.
---

# Apply Fix

You apply fixes to source code — either by using an existing ORL rule or by generating a new one on the fly. After applying a fix, you optionally save it as a reusable rule package.

## ORL via Docker

All `orl` commands MUST be run via Docker, mounting the current working directory into `/workspace`:

```bash
docker run -v "${PWD}:/workspace" gombocai/orl <command> [args...]
```

## Inputs

You receive from the `diagnose` skill (or directly from the user):

- **Finding**: What needs to be fixed (policy violation, file, line, classification reference)
- **Target file(s)**: The source code file(s) to fix
- **Language**: The ORL language ID (`terraform`, `hcl`, `cloudformation-yaml`, `cloudformation-json`, `bicep`, `docker`, `kubernetes`, `python`)
- **Status**: Whether an existing rule is available or a new rule is needed

## Path A: Existing Rule Available

When an existing rule covers the finding (identified by `diagnose`):

### Local rule (on disk)

If the rule is local (e.g., in `/orl-rules/final/`, `.orl-rules/`, or `.orl-fixes/`), use its path directly:

1. **Dry-run remediation** to preview changes:
   ```bash
   docker run -v "${PWD}:/workspace" gombocai/orl remediate -d --language <lang> -r <local-rule-path> <target-path>
   ```

2. **Show the diff** to the user and explain what will change.

3. **On confirmation**, apply the fix:
   ```bash
   docker run -v "${PWD}:/workspace" gombocai/orl remediate --language <lang> -r <local-rule-path> <target-path>
   ```

4. **Report** which files were changed and what was fixed.

### Remote rule (Gomboc Rules Service)

If the rule is in the Gomboc Rules Service, pull it first. Use the `--search` flag with compound queries — match by classification, resource, and language for precision:

1. **Pull the rule**:
   ```bash
   # Best: match by classification + language
   docker run -v "${PWD}:/workspace" -e RULE_SERVICE_TOKEN gombocai/orl rules pull \
     --search '(and (any "<classification-name>" $.classification) (eq $.metadata.language "<lang>"))'

   # Or by resource type + language
   docker run -v "${PWD}:/workspace" -e RULE_SERVICE_TOKEN gombocai/orl rules pull \
     --search '(and (any "<resource-type>" $.classification) (eq $.metadata.language "<lang>"))'
   ```

2. **Dry-run remediation** to preview changes:
   ```bash
   docker run -v "${PWD}:/workspace" gombocai/orl remediate -d --language <lang> -r <pulled-rule-dir> <target-path>
   ```

3. **Show the diff** to the user and explain what will change.

4. **On confirmation**, apply the fix:
   ```bash
   docker run -v "${PWD}:/workspace" gombocai/orl remediate --language <lang> -r <pulled-rule-dir> <target-path>
   ```

5. **Report** which files were changed and what was fixed.

## Path B: New Rule Needed

When no existing rule covers the finding, generate one:

### Step 1: Set Up the Language Expert

Invoke the appropriate `language-*-expert` skill for AST and syntax guidance:

| ORL Language | Expert Skill |
|---|---|
| `terraform` | `language-terraform-expert` |
| `hcl` | `language-hcl-expert` |
| `cloudformation-yaml` | `language-cloudformation-yaml-expert` |
| `cloudformation-json` | `language-cloudformation-json-expert` |
| `bicep` | `language-bicep-expert` |
| `docker` | `language-docker-expert` |
| `kubernetes` | `language-kubernetes-expert` |
| `python` | `language-python-expert` |

### Step 2: Create Rule Workspace

Create a temporary rule package directory in `.orl-fixes/` within the project:

```
.orl-fixes/<rule-name>/
├── workspace/              # Copy of affected file(s) WITH the violation
├── workspace_expected/     # Copy of affected file(s) AFTER the fix
├── <rule-name>.orl         # The rule (written in Step 4)
└── test.orl                # Test definition (written in Step 5)
```

1. Copy the affected source file(s) into `workspace/`
2. Create the corrected version in `workspace_expected/` — apply the fix manually to the copy
3. **NO COMMENTS** in workspace files — comments break diff-based testing

### Step 3: Explore the AST

Walk the workspace to understand the tree-sitter node structure:

```bash
docker run -v "${PWD}:/workspace" gombocai/orl walk workspace --language <lang> .orl-fixes/<rule-name>/workspace
```

Use the output to identify the exact node types, capture names, and nesting structure for the audit query.

### Step 4: Write the ORL Rule

Create `<rule-name>.orl` using the tree-sitter query patterns appropriate for the language:

```yaml
type: Ruleset
version: v1
metadata:
  name: gomboc-ai/<rule-name>
spec:
  template:
    language: <orl-language-id>
    audit_language: ast
  rules:
    - name: <descriptive-rule-name>
      audit: |
        <tree-sitter query>
      remediation:
        - command: replace|insert_after|insert_before|remove
          path: <capture-name>
          value: "<new value>"
```

**Language-specific query patterns:**

- **Terraform**: Use template helpers (`aResource`, `anAttribute`, `aMissingAttribute`, `aBlock`, `aMissingBlock`)
- **HCL (Terragrunt)**: Use raw HCL tree-sitter queries for `block`, `attribute`, `function_call` nodes
- **CloudFormation YAML**: Use raw tree-sitter YAML queries (`block_mapping_pair`, `flow_node`)
- **CloudFormation JSON**: Use JSON tree-sitter queries (`pair`, `object`, `array`)
- **Bicep**: Use raw tree-sitter queries; for missing properties use `replace` with template interpolation on `props_body`
- **Dockerfile**: Use Dockerfile tree-sitter grammar — `from_instruction`, `user_instruction`, `run_instruction`, `env_instruction`, `arg_instruction`
- **Kubernetes**: Use YAML tree-sitter queries scoped by `apiVersion`/`kind` predicates on `block_mapping_pair` nodes
- **Python**: Use Python tree-sitter grammar — `call`, `import_statement`, `assignment`, `keyword_argument`, `decorated_definition`

**Critical rules:**
- Captures used only for filtering MUST start with `_` (e.g., `@_type`)
- NEVER hardcode spaces in `value` — use `flags: { indent: "  " }`
- Use `|` (literal block scalar) for multi-line values, not `|-` or quotes
- Separate rules for "wrong value" vs "missing attribute" cases

### Step 5: Write the Test File

Create `test.orl`:

```yaml
type: Test
version: v1
metadata:
  name: <rule-name>-test
spec:
  rulespace: "."
  cases:
    - name: <Descriptive Test Name>
      language: <orl-language-id>
      workspace:
        path: ./workspace
      remediated_workspace:
        path: ./workspace_expected
      expected_report:
        errors: []
```

### Step 6: Test

```bash
cd .orl-fixes/<rule-name>
docker run -v "${PWD}:/workspace" gombocai/orl test .
```

If tests fail:
1. Examine the diff output to understand the mismatch
2. Adjust the rule or the expected files
3. Re-test (up to 5 iterations)

### Step 7: Apply to User's Code

Once tests pass:

1. **Dry-run** against the user's actual code:
   ```bash
   docker run -v "${PWD}:/workspace" gombocai/orl remediate -d --language <lang> -r .orl-fixes/<rule-name> <target-path>
   ```

2. **Show the diff** to the user.

3. **On confirmation**, apply:
   ```bash
   docker run -v "${PWD}:/workspace" gombocai/orl remediate --language <lang> -r .orl-fixes/<rule-name> <target-path>
   ```

4. **Report** which files were changed.

### Step 8: Save as Reusable Rule (Optional)

Ask the user: **"Save this fix as a reusable rule?"**

**If yes:**
1. Invoke the `add-metadata` skill on the rule package — pre-populate from the classification that triggered the finding:
   - `classifications` from the finding's policy name
   - `gomboc-ai/provider` from the classification's `gomboc-ai/providers`
   - `gomboc-ai/resource` from the matched resource type
2. Optionally invoke `push-rule` to publish to the Gomboc Rules Service

**If no:**
1. Ask if the user wants to keep the `.orl-fixes/` directory for reference
2. If not, clean up: remove `.orl-fixes/<rule-name>/`

## Pre-Completion Checklist

Before declaring a fix complete:
- [ ] `orl test .` passes with zero failures
- [ ] Workspace files have NO comments
- [ ] All filter-only captures use underscore prefix (`@_name`)
- [ ] `indent` flag used instead of hardcoded spaces in values
- [ ] Dry-run output matches expected changes
- [ ] User confirmed the diff before applying
