---
name: gomboc_community_flow_apply_fix
description: >-
  Use when applying a fix with an existing ORL rule or by generating a new one.
  Does not own save/release — callers (e.g. flow_fix Phase 3) handle enrich and
  push. Depends on: gomboc_community_know_orl_runtime_resolution,
  gomboc_community_know_language_guidance, gomboc_community_task_resolve_existing_rules,
  gomboc_community_cap_orl_remediate, gomboc_community_task_setup_rule_workspace,
  gomboc_community_task_write_orl_rule, gomboc_community_task_run_orl_test_loop.
---

# Flow: Apply Fix

Apply a fix for a finding — reuse an existing rule or generate one. Do not inline Docker/`orl` commands; use the listed dependencies.

**Does not** enrich or release rules. When a new package is generated under `.orl-fixes/`, leave it in place and return; save/release is owned by **`gomboc_community_flow_fix`** Phase 3 (or other explicit callers of enrich/release).

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
6. Report the package path under `.orl-fixes/` so the caller can optionally save/release.

## Constraints

- Never apply without engineer confirmation.
- Prefer caps/tasks over ad-hoc `docker run`.
- Do not call **`gomboc_community_task_enrich_rule`** or **`gomboc_community_task_release_rule`** from this flow.
