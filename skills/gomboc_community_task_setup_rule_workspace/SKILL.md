---
name: gomboc_community_task_setup_rule_workspace
description: >-
  Use when creating an ORL rule package directory with workspace and workspace_expected
  fixtures. Depends on: gomboc_community_know_language_guidance.
---

# Task: Setup Rule Workspace

## Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `package_path` | yes | Destination directory for the rule package. Callers derive a default (e.g. `./rules/<rule-name>/` or `.orl-fixes/<rule-name>/`) rather than asking the user. |
| `language` | yes | ORL language id |
| `fixtures` | yes | Before/after samples (from planner or real code) |

## Process

1. Create `<package_path>/` with `workspace/` and `workspace_expected/`.
2. Write violation fixtures into `workspace/` and expected remediated files into `workspace_expected/`.
3. Leave `.orl` / `test.orl` for **`gomboc_community_task_write_orl_rule`**.

## Constraints

- Do not run `orl test` here — that is **`gomboc_community_task_run_orl_test_loop`**.
- Prefer real engineer code as fixtures when called from apply-fix Path B.
