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

1. Load **`gomboc_community_know_language_guidance`**.
2. Explore AST with **`gomboc_community_cap_orl_walk`**.
3. Write `<name>.orl`:
   - First line: `# yaml-language-server: $schema=/app/orl-rules/schema/ruleset.json`
   - `spec.template.audit_language: ast`
   - Filter-only captures use `_` prefix; use `flags.indent` (no hardcoded spaces)
4. Write `test.orl` with negative/positive cases; when expected fixtures exist use `remediated_workspace.mode: ast` (never `comparison: ast`).
5. Prefer templates under `assets/templates/` when available.

## Constraints

- Do not push or enrich here.
- Hand off to **`gomboc_community_task_run_orl_test_loop`** with `rule_package` = this task’s `package_path`.
