---
name: convert-sentinel
description: Convert a HashiCorp Sentinel policy into one or more ORL rules. Reads a Sentinel policy from a URL or file path, analyzes its intent, decides audit-only vs fix strategy, builds the ORL rule package with tests, and optionally pushes it to the user's Gomboc account.
---

# Convert Sentinel Policy to ORL

You convert HashiCorp Sentinel policies into ORL (Open Remediation Language) rules. You read the Sentinel source, understand its intent, translate the enforcement logic into tree-sitter AST queries, build a tested rule package, and optionally publish it.

## ORL via Docker

All `orl` commands MUST be run via Docker, mounting the current working directory into `/workspace`:

```bash
docker run -v "${PWD}:/workspace" gombocai/orl <command> [args...]
```

## The Paradigm Shift

Understanding this difference is critical to a correct conversion:

- **Sentinel** checks the **Terraform State/Plan** — it has access to fully rendered objects, resolved variables, module relationships, and computed values (e.g., `tfplan.resource_changes`).
- **ORL** works on the **Source Code** (AST) — it uses tree-sitter queries to match and modify patterns directly in `.tf` files, before Terraform runs.

Because of this, converting a Sentinel policy is NOT a 1:1 translation. An ORL rule defines patterns based on how developers *write* code, not the final computed state. Some Sentinel checks have no ORL equivalent (e.g., checking computed outputs or cross-module references).

## Inputs

You receive:
- A Sentinel policy — either as:
  - A **URL** to a `.sentinel` file (e.g., a GitHub raw link, a Terraform registry link)
  - A **file path** to a local `.sentinel` file
- Optionally: example Terraform code the policy targets, or Sentinel mock data files

## Workflow

### Step 1: Retrieve and Analyze the Sentinel Policy

1. **If URL provided:** Fetch the policy content using `web_fetch`
2. **If file path provided:** Read the file
3. Parse the Sentinel policy to identify:
   - **Target resources**: What Terraform resource types does it check? (e.g., `aws_instance`, `aws_ami`)
   - **Target attributes**: What properties does it enforce? (e.g., `most_recent`, `ami`, `owners`)
   - **Enforcement logic**: What conditions trigger a violation? (e.g., missing attribute, wrong value, invalid reference)
   - **Severity**: `advisory`, `soft-mandatory`, or `hard-mandatory`
   - **Imports used**: `tfplan`, `tfstate`, `tfconfig`, `tfrun` — these indicate what data the policy inspects

### Step 2: Assess Conversion Strategy

Determine what kind of ORL rule(s) to create:

| Sentinel Pattern | ORL Strategy | Reason |
|-----------------|-------------|--------|
| Checks a single attribute value (e.g., `encryption = true`) | **Fix rule** — replace/insert the correct value | Deterministic, safe to auto-fix |
| Checks attribute is present (e.g., `tags` must exist) | **Fix rule** — insert default if missing | Deterministic with a known default |
| Checks attribute references a specific resource type (e.g., `ami` must reference `data.aws_ami`) | **Fix rule** — replace with data source reference | Deterministic if a canonical pattern exists |
| Checks computed values, cross-module refs, or runtime state | **Audit-only rule** — flag the pattern, no auto-fix | Cannot determine correct value from source code alone |
| Checks values that depend on user/org context (e.g., allowed VPC IDs, approved AMI owners) | **Fix with variables** or **Audit-only** | Needs user input or org-specific config |

**Present the strategy to the user** before proceeding:

```
Sentinel policy analysis:

  Policy: require-most-recent-ami-version
  Severity: hard-mandatory
  Target resources: aws_instance, data.aws_ami

  Conversion plan:
  1. [FIX]        aws_instance ami must reference data.aws_ami (replace hardcoded AMIs)
  2. [FIX]        data.aws_ami must have most_recent = true
  3. [FIX]        data.aws_ami must have valid owners
  4. [AUDIT-ONLY] data.aws_ami must have approved name filter (org-specific)

  Proceed? [Y/n]
```

### Step 3: Decompose into Sub-Rules

Sentinel policies often enforce multiple conditions in one policy. Decompose into separate ORL rules, each handling one concern:

- **One rule per attribute enforcement** (e.g., one rule for `most_recent`, one for `owners`)
- **Separate "wrong value" from "missing attribute"** rules — these need different audit queries and remediation commands
- **Use rule priority** to control execution order when rules depend on each other (lower priority number = runs first)

Name each rule following the convention: `gomboc-ai/terraform/<provider>/<resource>/<requirement>`

### Step 4: Build Test Workspace

Create workspace files that exercise all code paths from the original Sentinel policy:

```
<rule-package>/
├── workspace/               # Terraform files WITH violations
│   ├── valid.tf             # Already compliant — should not be modified
│   ├── missing_attribute.tf # Attribute absent entirely
│   ├── wrong_value.tf       # Attribute present but incorrect
│   └── invalid_reference.tf # References wrong resource type
├── workspace_expected/      # Terraform files AFTER remediation
│   ├── valid.tf             # Unchanged
│   ├── missing_attribute.tf # Attribute added with correct value
│   ├── wrong_value.tf       # Value replaced
│   └── invalid_reference.tf # Reference corrected
├── <rule-name>.orl          # The rule (written in Step 5)
└── test.orl                 # Test definition (written in Step 6)
```

**Map Sentinel mock data to workspace files:** If the user provides Sentinel mock files, extract the resource configurations and use them as the basis for workspace test files.

**For audit-only rules:** `workspace/` and `workspace_expected/` are identical (no code changes expected).

**NO COMMENTS** in workspace files — comments break diff-based testing.

### Step 5: Write the ORL Rules

Use the `build-rule` skill's Terraform-specific knowledge to write tree-sitter queries. Since Sentinel policies target Terraform, use Terraform template helpers:

- `aResource("type", ...)` — Match a resource by type
- `anAttribute("key")` — Match an attribute by name
- `anAttributeValueEq("key", "value")` — Match attribute with specific value
- `anAttributeValueNotEq("key", "value")` — Match attribute NOT equal to value
- `aMissingAttribute("key")` — Match resource missing an attribute
- `aBlock("name")` — Match a block by name
- `aMissingBlock("name")` — Match missing block

**Key Terraform mechanics for Sentinel conversions:**
- Variable references (`var.x`) produce `identifier` nodes — rules must NOT modify these
- `true`/`false` are unquoted booleans in HCL (tree-sitter: `literal_value`)
- `data` blocks use `aResource("aws_ami", ...)` with the data source name
- String values are quoted: `"value"` (tree-sitter: `string_lit`)
- Use `skip_finding` to exclude already-compliant resources

**For each rule:**
1. Write the audit query targeting the violation pattern
2. Write the remediation commands (`replace`, `insert_after`, `insert_before`, `remove`)
3. Add `skip_finding` to prevent matching compliant resources
4. Use `flags: { indent: "  " }` instead of hardcoded spaces
5. Use `_` prefix for filter-only captures

### Step 6: Write Tests and Validate

Create `test.orl`:

```yaml
# yaml-language-server: $schema=../../schema/test.json
rulesets:
  - <rule-name>.orl

tests:
  - name: "<Descriptive test name>"
    document:
      path: ./workspace
      language: terraform
    remediated_workspace:
      path: ./workspace_expected
      mode: ast
```

Run tests:

```bash
docker run -v "${PWD}:/workspace" gombocai/orl test .
```

If tests fail, iterate: examine diffs, adjust the rule or expected files, re-test. Maximum 5 iterations.

### Step 7: Add Metadata

Add metadata to each `.orl` file:

```yaml
metadata:
  name: gomboc-ai/terraform/<provider>/<resource>/<requirement>
  display_name: <Human Readable Title, max 10 words>
  description: |
    ## Description

    <What this rule enforces, converted from Sentinel policy: policy-name>

    Original Sentinel severity: <advisory|soft-mandatory|hard-mandatory>
  classifications:
    - gomboc-ai/policy/<appropriate-classification>
  annotations:
    contributed-by: <user>
    gomboc-ai/provider: <AWS|Azure|GCP>
    gomboc-ai/resource: <resource_type>
    gomboc-ai/visibility: public
    gomboc-ai/public-rule-bodies: "true"
    gomboc-ai/description-plain: "<one-line summary>"
    gomboc-ai/source: "sentinel"
    gomboc-ai/sentinel-policy: "<original-sentinel-policy-name>"
```

The `gomboc-ai/source: "sentinel"` and `gomboc-ai/sentinel-policy` annotations preserve provenance — they record that this rule was converted from a Sentinel policy and which one.

### Step 8: Prompt to Share

After the rule package is complete and tests pass, ask the user:

```
Rule package complete! All tests passing.

  Rules created: <N>
  Findings: <N>
  Fixes: <N>

  Original Sentinel policy: <policy-name>
  ORL rules:
    - <rule-1-name> (fix)
    - <rule-2-name> (fix)
    - <rule-3-name> (audit-only)

Would you like to share this rule to your Gomboc account?
  1. Yes — push to my account (requires RULE_SERVICE_TOKEN)
  2. No — keep locally only

[1/2]
```

**If yes:** Invoke the `push-rule` skill:
1. Verify `RULE_SERVICE_TOKEN` is set
2. Run tests one final time
3. Push: `docker run -v "${PWD}:/workspace" -e RULE_SERVICE_TOKEN gombocai/orl rules push .`
4. Report success with the rule name(s)

**If no:** Report the local path to the rule package.

## Conversion Limitations

Be transparent with the user about what cannot be converted:

| Sentinel Capability | ORL Equivalent | Notes |
|-------------------|---------------|-------|
| `tfplan.resource_changes` — checks planned changes | No direct equivalent | ORL works on source code, not plan output |
| `tfstate` — checks current state | No direct equivalent | ORL cannot read remote state |
| `tfrun` — checks workspace metadata | No equivalent | Runtime context not available at source level |
| `tfconfig.module_calls` — checks module composition | Partial — can check `.tf` files in modules | Cannot resolve remote module sources |
| Cross-resource references (e.g., "security group must reference this VPC") | Audit-only | Cannot validate computed references from source |
| Computed values (`count.index`, `each.key`) | Skip these | Variables/expressions should not be modified |
| `print()` statements | Omit | Sentinel debugging, no ORL equivalent |

When a Sentinel check cannot be converted, explain why and suggest the closest ORL alternative (usually audit-only).

## Reference Examples

The directory `../../references/examples/sentinel/` contains a complete worked example of converting the `require-most-recent-ami-version` Sentinel policy into both audit-only and fix ORL rules.
