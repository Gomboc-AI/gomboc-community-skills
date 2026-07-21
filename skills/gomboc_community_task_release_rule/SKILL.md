---
name: gomboc_community_task_release_rule
description: >-
  Use when validating a rule package and pushing it to the Gomboc Rules Service. Depends
  on: gomboc_community_know_orl_runtime_resolution, gomboc_community_know_release_checklist,
  gomboc_community_cap_run_orl_test, gomboc_community_cap_orl_rules_push.
---

# Task: Release Rule

Validate then publish a community ORL rule package to the Rules Service (private to the user’s account).

## Prerequisites

- Runtime per **`gomboc_community_know_orl_runtime_resolution`**
- Host token resolved per that know skill (`GOMBOC_PAT`, else legacy `RULE_SERVICE_TOKEN` with warning) — never log the value

## Process

1. **Structure** — package has named `.orl`, `test.orl`, `workspace/`, `workspace_expected/` (see **`gomboc_community_know_release_checklist`**).
2. **Test** — **`gomboc_community_cap_run_orl_test`**. Stop on failure.
3. **Push** — **`gomboc_community_cap_orl_rules_push`**.
4. **Report** — rule name(s) and success/failure from the CLI.

## After push

To re-fetch published rules, use **`gomboc_community_cap_orl_rules_pull`** (not ad-hoc Docker).

## Constraints

- Do not push with failing tests.
- Do not invent CLI flags.
