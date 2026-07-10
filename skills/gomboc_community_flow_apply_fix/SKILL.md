---
name: gomboc_community_flow_apply_fix
description: >-
  Use when applying a fix with an existing ORL rule or by generating a new one; optional
  save/release. Depends on: gomboc_community_know_orl_runtime_resolution,
  gomboc_community_know_language_guidance, gomboc_community_task_resolve_existing_rules,
  gomboc_community_cap_orl_remediate, gomboc_community_task_setup_rule_workspace,
  gomboc_community_task_write_orl_rule, gomboc_community_task_run_orl_test_loop,
  gomboc_community_task_enrich_rule, gomboc_community_task_release_rule.
---

# Flow: Apply Fix

Apply a fix for a finding — reuse an existing rule or generate one. Do not inline Docker/`orl` commands; use the listed dependencies.

## Inputs

From **`gomboc_community_flow_diagnose`** (or the user):

| Parameter | Description |
|-----------|-------------|
| Finding | Policy violation, file, classification |
| Target path(s) | Code to fix |
| Language | ORL language id |
| Rule status | existing / partial / none |

## Path A — Existing rule

1. Resolve a rule path with **`gomboc_community_task_resolve_existing_rules`**.
2. Dry-run with **`gomboc_community_cap_orl_remediate`** (`dry_run: true`).
3. Show the diff; on confirmation, remediate with `dry_run: false`.
4. Report changed files.

## Path B — New rule needed

1. Load **`gomboc_community_know_language_guidance`** for language/AST notes.
2. **`gomboc_community_task_setup_rule_workspace`** under `.orl-fixes/<rule-name>/` using the engineer’s real files as fixtures (no comments in workspace files).
3. **`gomboc_community_task_write_orl_rule`** (uses **`gomboc_community_cap_orl_walk`**).
4. **`gomboc_community_task_run_orl_test_loop`** (max 5 attempts).
5. Dry-run then apply via **`gomboc_community_cap_orl_remediate`** against the user’s target path (confirm before apply).

## Optional save / release

Ask whether to save the generated package as a reusable rule.

- Yes → **`gomboc_community_task_enrich_rule`** (pre-populate from the finding’s classification), then optionally **`gomboc_community_task_release_rule`**.
- No → ask whether to keep or delete `.orl-fixes/<rule-name>/`.

## Constraints

- Never apply without engineer confirmation.
- Prefer caps/tasks over ad-hoc `docker run`.
