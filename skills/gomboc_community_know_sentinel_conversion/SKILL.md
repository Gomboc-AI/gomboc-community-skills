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

## Constraints

- Prefer source-level patterns developers actually write.
- Decompose multi-condition Sentinel policies into multiple ORL rules when needed.
- Load **`gomboc_community_flow_convert_sentinel`** for the full pipeline.
