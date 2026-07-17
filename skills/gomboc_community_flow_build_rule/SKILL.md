---
name: gomboc_community_flow_build_rule
description: >-
  Use when building an ORL rule package — workspace, AST explore, write rule/tests, test
  loop. Depends on: gomboc_community_know_orl_runtime_resolution,
  gomboc_community_know_language_guidance, gomboc_community_task_setup_rule_workspace,
  gomboc_community_cap_orl_walk, gomboc_community_task_write_orl_rule,
  gomboc_community_task_run_orl_test_loop.
---

# Flow: Build Rule

Orchestrate creation of a tested ORL rule package. Language/AST details live in **`gomboc_community_know_language_guidance`** and `references/` — do not duplicate them here.

## Key references

- `references/orl-docs.md`, `references/grammar.md`, `references/expr-lang.md`
- Language AST helpers under `references/`
- Templates under `assets/templates/`

## Process

### 1 — Setup workspace

Default `package_path` to `./rules/<rule-name>/` (cwd-relative), where `<rule-name>` is the rule's `metadata.name` with `/` replaced by `-` (e.g. `gomboc-ai/terraform/aws/rds-deletion-protection` → `./rules/gomboc-ai-terraform-aws-rds-deletion-protection/`). Do not ask the user for a directory — only use a different path if the user already gave one.

Execute **`gomboc_community_task_setup_rule_workspace`** (fixtures from plan or real code). No comments in workspace files.

### 2 — Explore AST

Execute **`gomboc_community_cap_orl_walk`** on the package workspace.

### 3 — Write rule + tests

Execute **`gomboc_community_task_write_orl_rule`**. Require:

- First line: `# yaml-language-server: $schema=/app/orl-rules/schema/ruleset.json`
- `spec.template.audit_language: ast`
- `test.orl` uses `remediated_workspace.mode: ast` when expected fixtures exist (never `comparison: ast`)

### 4 — Test loop

Execute **`gomboc_community_task_run_orl_test_loop`**. Optionally dry-run remediate via **`gomboc_community_cap_orl_remediate`** against `./workspace` while debugging.

### 5 — Template helpers (optional)

Via **`gomboc_community_know_orl_runtime_resolution`**, run `orl language <lang>` to list template helpers for the target language.

## Critical best practices

1. AST queries, not bare substring matching for structure
2. Filter-only captures use `_` prefix
3. `flags.indent` instead of hardcoded spaces in remediation values
4. Literal block `|` for multi-line values
5. Separate rules for wrong-value vs missing-attribute
6. No comments in workspace fixtures

## Pre-completion

- [ ] Tests pass (`gomboc_community_cap_run_orl_test` / test loop)
- [ ] Plan test cases covered
- [ ] Best-practice items above satisfied
- [ ] Metadata sufficient for later enrich/review (or deferred to those skills)

## Constraints

- Do not inline language-specific query guides — load **`gomboc_community_know_language_guidance`**.
- Prefer tasks/caps over ad-hoc Docker commands.
