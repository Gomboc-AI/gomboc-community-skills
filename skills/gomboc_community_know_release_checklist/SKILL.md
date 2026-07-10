---
name: gomboc_community_know_release_checklist
description: >-
  Use when checking community rule release readiness — naming, metadata, package layout,
  and test gates. No side effects.
---

# Know: Release Checklist

Use when reviewing or releasing a community ORL rule package.

## Blocking

- [ ] `orl test .` passes (via `gomboc_community_cap_run_orl_test`)
- [ ] Package has named `.orl`, `test.orl`, `workspace/`, `workspace_expected/`
- [ ] `metadata.name` follows community naming (`gomboc-ai/...`)
- [ ] Required metadata present: `display_name`, `description`, `classifications`, visibility annotations
- [ ] At least one negative and one positive test case where applicable

## Required community annotations

- `gomboc-ai/visibility: public`
- `gomboc-ai/public-rule-bodies: "true"`
- `gomboc-ai/provider`, `gomboc-ai/resource`, `gomboc-ai/description-plain`
- `contributed-by`

## Non-blocking recommendations

- Stronger classification coverage
- Extra edge-case fixtures
- Clearer `display_name` / description

Flows that auto-fix gaps: **`gomboc_community_flow_review_rule`**.  
Publish: **`gomboc_community_task_release_rule`**.
