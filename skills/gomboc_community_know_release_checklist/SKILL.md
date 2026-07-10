---
name: gomboc_community_know_release_checklist
description: >-
  Use when checking community rule release readiness — naming, metadata, package layout,
  and test gates. No side effects.
---

# Know: Release Checklist

Criteria for reviewing or releasing a community ORL rule package. Auto-fix orchestration: **`gomboc_community_flow_review_rule`**. Publish: **`gomboc_community_task_release_rule`**.

## Blocking

- [ ] `orl test .` passes (`gomboc_community_cap_run_orl_test`)
- [ ] Package has named `.orl`, `test.orl`, `workspace/`, `workspace_expected/`
- [ ] `metadata.name` follows `gomboc-ai/<language>/<framework>/<requirement>`
- [ ] `.orl` filename matches `metadata.name` with `/` → `-`
- [ ] Required metadata: `display_name`, `description`, `classifications`
- [ ] Community annotations present (below)
- [ ] `test.orl` uses `mode: ast` when expected fixtures exist (not `comparison: ast`)
- [ ] No comments in workspace fixtures
- [ ] At least one negative and one positive test case where applicable

## Required community annotations

- `contributed-by`
- `gomboc-ai/visibility: public`
- `gomboc-ai/public-rule-bodies: "true"`
- `gomboc-ai/provider`, `gomboc-ai/resource`, `gomboc-ai/description-plain`

## Recommended (non-blocking)

- Impact / risk / severity scores and statements
- `gomboc-ai/example` diff
- Stronger classification coverage and edge-case fixtures
- Output artifacts under `outputs/` (plan, build, review, assessment)

## Classification prefix

Classifications should use the `gomboc-ai/policy/` prefix (prepend when missing).
