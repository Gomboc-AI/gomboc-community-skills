---
name: gomboc_community_task_write_orl_rule
description: >-
  Use when authoring the main .orl rule and test.orl for a package using tree-sitter AST
  queries. Depends on: gomboc_community_know_language_guidance,
  gomboc_community_cap_orl_walk.
---

# Task: Write ORL Rule

## Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `package_path` | yes | Rule package with workspace fixtures |
| `language` | yes | ORL language id |
| `objective` | yes | What to audit/remediate |
| `remediation_type` | yes | FULL_REMEDIATION \| AUDIT_ONLY \| … |

## Process

1. Explore AST with **`gomboc_community_cap_orl_walk`**.
2. Write `<name>.orl` with `metadata` stub and `spec` (audit + optional remediation).
3. Write `test.orl` covering negative and positive cases.
4. Consult **`gomboc_community_know_language_guidance`** for language gotchas.

## Constraints

- Do not push or enrich here.
- Hand off to **`gomboc_community_task_run_orl_test_loop`** for validation.
