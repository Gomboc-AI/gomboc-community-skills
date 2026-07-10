---
name: gomboc_community_flow_review_rule
description: >-
  Use when evaluating a rule package against release standards, auto-fixing blocking gaps,
  and producing a report. Depends on: gomboc_community_know_orl_runtime_resolution,
  gomboc_community_know_release_checklist, gomboc_community_cap_run_orl_test,
  gomboc_community_task_enrich_rule.
---

# Flow: Review Rule

Release-readiness engineer for ORL packages: evaluate gaps, **auto-fix blocking issues and required metadata**, ask only when values cannot be inferred. Checklist criteria live in **`gomboc_community_know_release_checklist`** — load that; do not restate the full checklist here.

## Inputs

- Path to a rule package (`.orl`, `test.orl`, `workspace/`, `workspace_expected/`)

## Process

### Step 1 — Test gate

**`gomboc_community_cap_run_orl_test`**. On failure, stop and report — do not auto-cleanup past failing tests.

### Step 2 — Locate or create assessment

Read `outputs/rule-assessment.md` if present. Otherwise perform a lightweight 9-criterion assessment (completeness, accuracy, test coverage, maintainability, conciseness, side effects, tool usage, safe execution, metadata) and write `outputs/rule-assessment.md`.

### Step 3 — Fix release-process gaps

Against **`gomboc_community_know_release_checklist`**, auto-fix when deterministic; ask when not.

| Area | Action |
|------|--------|
| Naming | `metadata.name` = `gomboc-ai/<lang>/<framework>/<requirement>`; rename `.orl` to match (`/` → `-`); update `test.orl` refs |
| Metadata | Infer `display_name`, `description`, provider/resource, scores when possible; default `visibility`/`public-rule-bodies`; **ask** for `contributed-by` / reviewer name |
| Prefer | **`gomboc_community_task_enrich_rule`** when filling standard community metadata fields |
| `test.orl` | Add schema header; replace `comparison: ast` → `mode: ast`; fill expected counts from Step 1 |
| Workspace | Report file-count mismatches; strip comments from fixtures then re-test |
| Classifications | Prepend `gomboc-ai/policy/` when missing |
| Outputs | Generate missing `outputs/*.md` placeholders (plan/build/review/test-plan/enrich/scanner-validation) |

### Step 4 — Ask for missing values

Single consolidated prompt for anything that could not be inferred; apply answers.

### Step 5 — Re-test

**`gomboc_community_cap_run_orl_test`**. On failure, revert the last risky change and report.

### Step 6 — Re-assess

Archive prior assessment to `outputs/rule-assessment-pre-cleanup.md`. Produce a fresh `outputs/rule-assessment.md` reflecting post-fix state. Compare scores; if still DENY/CONDITIONAL, list remaining manual work.

### Step 7 — Report

Write `outputs/cleanup-report.md` (changes made, re-assessment, recommended non-blocking improvements) and print it.

## Ask vs auto-fix

| Situation | Action |
|-----------|--------|
| Deterministic from rule content | Auto-fix |
| Safe default (e.g. visibility public) | Auto-fix with default |
| Reasonable inference | Auto-fix; note in report |
| Personal/org (contributor, reviewer) | Ask |
| Ambiguous / misrepresentation risk | Ask |
| Tests fail after a fix | Revert and report |

## Out of scope

- New test cases / rewriting audit or remediation logic
- Push/release — use **`gomboc_community_task_release_rule`**
