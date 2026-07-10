---
name: gomboc_community_flow_create_rule
description: >-
  Use when creating an ORL rule end-to-end — plan, build, review, enrich, optional
  release. Entry point for /create-rule. Depends on: gomboc_community_task_orl_planner,
  gomboc_community_flow_build_rule, gomboc_community_flow_review_rule,
  gomboc_community_task_enrich_rule, gomboc_community_task_release_rule.
---

# Flow: Create Rule

Orchestrates the community rule-creation pipeline. Commands should load this skill and follow the phases below.

## Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `policy_description` | yes | What to enforce |
| `language` | yes | ORL language id |
| `resource` | no | Resource or construct |

## Process

### Phase 1 — Plan

Execute **`gomboc_community_task_orl_planner`**. Ask the user to confirm `plan.md` before continuing.

### Phase 2 — Build

Execute **`gomboc_community_flow_build_rule`** from the confirmed plan. Show test results.

### Phase 3 — Review

Execute **`gomboc_community_flow_review_rule`** on the package.

### Phase 4 — Enrich

Execute **`gomboc_community_task_enrich_rule`**. Show metadata added.

### Phase 5 — Release (optional)

Ask whether to push to the Rules Service. If yes: **`gomboc_community_task_release_rule`**.

## Constraints

- User confirmation between plan and build.
- Do not push with failing tests.
