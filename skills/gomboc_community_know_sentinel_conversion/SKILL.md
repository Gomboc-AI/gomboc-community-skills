---
name: gomboc_community_know_sentinel_conversion
description: >-
  Use when converting HashiCorp Sentinel policies to ORL and you need the state/plan vs
  source-AST paradigm and conversion limits. No side effects.
---

# Know: Sentinel Conversion

## Paradigm shift

- **Sentinel** checks Terraform **state/plan** — rendered objects, resolved variables, computed values.
- **ORL** works on **source AST** — tree-sitter patterns in `.tf` (and related) files before apply.

Conversion is not 1:1. Some Sentinel checks have no ORL equivalent (computed outputs, deep cross-module resolution).

## Strategy categories

| Sentinel intent | ORL approach |
|-----------------|--------------|
| Fixed attribute / boolean | `FULL_REMEDIATION` |
| Value depends on org context | `AUDIT_ONLY` |
| Only visible in plan/state | Document as unconvertible / manual |

## Detailed conversion strategy

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

## Constraints

- Prefer source-level patterns developers actually write.
- Decompose multi-condition Sentinel policies into multiple ORL rules when needed.
- Load **`gomboc_community_flow_convert_sentinel`** for the full pipeline.
