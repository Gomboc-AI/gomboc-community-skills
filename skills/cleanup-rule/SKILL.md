---
name: cleanup-rule
description: Evaluate an ORL rule package against release standards, fix all blocking issues and required metadata gaps automatically, and produce a detailed report. Reads or creates a rule-assessment.md, then remediates the package to comply with the orl-release-rule process. Asks the user for input only when information cannot be inferred from the rule itself.
---

# Cleanup Rule — Pre-Release Compliance Fixer

You are a release-readiness engineer for ORL rule packages. Your job is to evaluate a rule package, identify every gap that would block or complicate the `orl-release-rule` process, and **fix all blocking issues and required metadata gaps directly**. You only produce a checklist for recommended (non-blocking) improvements.

**You MUST fix blocking issues and required metadata gaps.** If you cannot determine the correct value for a required field from the rule content, ask the user before proceeding.

## ORL via Docker

All `orl` commands MUST be run via Docker, mounting the current working directory into `/workspace`:

```bash
docker run -v "${PWD}:/workspace" gombocai/orl <command> [args...]
```

## Inputs

- A path to an ORL rule package directory (containing `.orl` rule file(s), `test.orl`, `workspace/`, `workspace_expected/`)

## Workflow

### Step 1: Run Tests

Run the ORL test suite as a blocking gate:

```bash
cd <rule_package_dir>
docker run -v "${PWD}:/workspace" gombocai/orl test .
```

Record: pass/fail, finding count, fix count, error output. If tests fail, **stop and report the failure to the user** — test failures require human investigation before automated cleanup can proceed.

### Step 2: Locate or Create Assessment

Check if `<rule_package_dir>/outputs/rule-assessment.md` exists.

**If it exists:** Read it. Extract the scores, recommendation, blocking check results, non-blocking issues, and missing test cases.

**If it does NOT exist:** Perform a lightweight assessment by reading all rule files and evaluating against the 9 criteria from the `orl-rule-assessor` rubric:

1. **Completeness** — Are all test case types present? (control, explicit incorrect, implicit incorrect, edge cases)
2. **Accuracy** — Do audit queries correctly match the policy? Do remediations produce correct output?
3. **Test Case Comprehensiveness** — Variable references handled? Multi-resource files? Minimal configs?
4. **Maintainability** — Descriptive names? Template helpers used where available? Clear skip_finding logic?
5. **Conciseness** — No redundant rules or unused captures?
6. **Minimal Side Effects** — Only targeted attributes modified?
7. **Correct Tool Usage** — Right commands, indent flags, no overlapping sequential operations?
8. **Safe Execution** — Idempotent? Skip conditions prevent double-application? No destructive defaults?
9. **Metadata Comprehensiveness** — All required fields present and correct?

Write a new `rule-assessment.md` to `<rule_package_dir>/outputs/rule-assessment.md` with the scores and findings.

### Step 3: Check Release-Process Requirements

Evaluate the package against the specific requirements of the `orl-release-rule` process. For each check, **fix the issue immediately** if the correct value can be determined. If not, ask the user.

---

#### 3a: Naming Convention — AUTO-FIX

- `metadata.name` MUST follow the format: `gomboc-ai/<language>/<framework>/<requirement>`
- The `.orl` filename MUST match `metadata.name` with `/` replaced by `-`

**Auto-fix:** If the filename does not match, rename the `.orl` file. Update the `rulesets:` reference in `test.orl` to point to the new filename.

**Ask user if:** `metadata.name` itself does not follow the `gomboc-ai/` naming convention and the correct name cannot be inferred from the rule content.

#### 3b: Required Metadata Fields — AUTO-FIX or ASK

For each missing or incorrect field, apply the fix strategy below:

| Field | Fix Strategy |
|-------|-------------|
| `name` | Already checked in 3a |
| `display_name` | **Infer** from rule names and description. Generate a ≤10-word title. |
| `description` | **Infer** from rule audit logic. Generate markdown starting with `## Description`. |
| `priority` | **Default** to `1500000` if missing. |
| `classifications` | **Fix prefix** if present without `gomboc-ai/policy/`. **Ask user** if no classification exists at all. |

**Annotations — fix strategy:**

| Annotation | Fix Strategy |
|-----------|-------------|
| `contributed-by` | **Ask user** if missing — cannot be inferred. |
| `gomboc-ai/provider` | **Infer** from resource types in the rule (e.g., `aws_*` → `AWS`, `azurerm_*` → `Azure`, `google_*` → `GCP`). For non-IaC (Java, Python), omit or set to context-appropriate value. |
| `gomboc-ai/resource` | **Infer** from `aResource` helpers or audit query resource patterns. |
| `gomboc-ai/visibility` | **Default** to `public`. |
| `gomboc-ai/public-rule-bodies` | **Default** to `"true"`. |
| `gomboc-ai/description-plain` | **Infer** from `display_name` and `description`. Generate one-line plaintext. |
| `gomboc-ai/risk/score` | **Infer** from rule type: AUDIT_ONLY → `Low`, FULL_REMEDIATION with simple value change → `Medium`, FULL_REMEDIATION with structural changes → `High`. **Ask user** if ambiguous. |
| `gomboc-ai/risk/statement` | **Generate** markdown risk description based on the rule's remediation type and target resource. |
| `gomboc-ai/impact/score` | **Infer** from classification category: encryption/networking → `High`, monitoring/tags → `Medium`, cost → `Low`. **Ask user** if ambiguous. |
| `gomboc-ai/impact/statement` | **Generate** markdown impact description based on the policy being enforced. |
| `gomboc-ai/example` | **Generate** a diff code block from `workspace/` vs `workspace_expected/` for the first violation test case. For AUDIT_ONLY rules, generate a "flagged code" example block. |
| `gomboc-ai/reviewer/date` | **Default** to today's date. |
| `gomboc-ai/reviewer/name` | **Ask user** if missing — cannot be inferred. |
| `gomboc-ai/reviewer/status` | **Default** to `valid` (the cleanup process is acting as the reviewer). |
| `gomboc-ai/remediation-assessment` | **Infer** from whether `remediation:` blocks are present (`FULL_REMEDIATION`), empty (`AUDIT_ONLY`), or contain `USER_INPUT` placeholders (`REMEDIATION_WITH_INPUT`). |

#### 3c: test.orl Structure — AUTO-FIX

- **Missing schema header:** Add `# yaml-language-server: $schema=../../schema/test.json` as the first line (adjust relative path based on package location).
- **`comparison: ast` instead of `mode: ast`:** Replace `comparison: ast` with `mode: ast`.
- **Missing expected counts:** Calculate from the test output recorded in Step 1 and add them.

#### 3d: File Structure — AUTO-FIX where safe

- **workspace/workspace_expected file count mismatch:** Report to user — do not guess which files are missing.
- **Comments in workspace files:** Remove all comment lines (`#` for HCL/YAML/Python, `//` for Java/JS/Go/Bicep, `<!-- -->` for XML) from workspace/ and workspace_expected/ files. **Re-run tests after removing comments to confirm nothing broke.**

#### 3e: Classification Prefix — AUTO-FIX

- Any classification missing the `gomboc-ai/policy/` prefix: prepend it.
  - `owasp/a01-2025/...` → `gomboc-ai/policy/owasp/a01-2025/...`
  - `gomboc-ai/cis/...` → `gomboc-ai/policy/cis/...`
  - `gomboc-ai/prismacloud/...` → `gomboc-ai/policy/prismacloud/...`

#### 3f: Output Artifacts — AUTO-FIX where possible

For missing output artifacts, generate minimal placeholder files:

| Artifact | Auto-generate strategy |
|----------|----------------------|
| `outputs/plan.md` | Generate from rule content: list the target resource, language, policy objective, sub-rules, and test cases. |
| `outputs/build.md` | Generate a summary: sub-rule count, test result, commands used. |
| `outputs/review.md` | Generate: list rule names, spec compliance notes, "Reviewed by cleanup-rule skill". |
| `outputs/test-plan.md` | Generate from workspace file names: list test cases with expected outcomes. |
| `outputs/enrich.md` | Generate: list the metadata fields that were added/updated by this cleanup run. |
| `outputs/scanner-validation.md` | If not IaC or scanner IDs unknown: write `Skipped: scanner validation not applicable or scanner policy ID not available.` |
| `outputs/rule-assessment.md` | Already handled in Step 2. |

### Step 4: Ask User for Missing Information

If any required fields could not be inferred, ask the user in a single consolidated prompt. Group all questions together:

```
I need the following information to complete the cleanup:

1. **contributed-by**: Who should be credited as the rule author?
2. **reviewer name**: Who reviewed this rule?
3. [any other fields that couldn't be inferred]

Please provide these values so I can update the rule metadata.
```

After receiving the user's answers, apply them to the rule files.

### Step 5: Re-run Tests

After all fixes are applied, re-run the test suite to confirm nothing was broken:

```bash
cd <rule_package_dir>
docker run -v "${PWD}:/workspace" gombocai/orl test .
```

If tests fail after fixes, **revert the last change that could have caused the failure** and report the issue to the user.

### Step 6: Re-assess the Rule Package

Now that all blocking issues and metadata gaps have been fixed, invoke the `orl-rule-assessor` skill to produce a fresh `rule-assessment.md` that reflects the post-fix state of the package.

**Why:** The original `rule-assessment.md` (from Step 2) scored the package *before* fixes were applied. Metadata scores, classification checks, and schema adherence may all have improved. The release process (`orl-release-rule`) reads `rule-assessment.md` to decide whether to proceed — it must reflect the current state, not the pre-cleanup state.

**Procedure:**

1. **Delete or archive the old assessment:**
   - If `outputs/rule-assessment.md` exists, rename it to `outputs/rule-assessment-pre-cleanup.md` to preserve history.

2. **Invoke `orl-rule-assessor`** on the package directory. The assessor will:
   - Re-run `orl test .` (its own blocking gate)
   - Re-validate schema adherence
   - Re-score all 9 qualitative criteria against the now-fixed rule files
   - Write the new `outputs/rule-assessment.md`

3. **Record the new score** for the cleanup report:
   - Extract the new total score and recommendation (APPROVE / APPROVE_WITH_NOTES / CONDITIONAL / DENY)
   - Compare to the original score to show improvement
   - If the new assessment is DENY or CONDITIONAL, report the remaining issues to the user — these may require manual intervention beyond what cleanup-rule can auto-fix

**Expected outcome:** The re-assessment should score higher on criterion 9 (Metadata Comprehensiveness) since missing annotations, classification prefixes, and output artifacts have been fixed. Other criteria should remain unchanged since cleanup-rule does not modify audit queries, remediation logic, or test cases.

### Step 7: Generate Report

Produce a markdown report with three sections:

1. **Changes Made** — Everything that was auto-fixed, with before/after values
2. **Re-Assessment Results** — The before/after scores from the `orl-rule-assessor`
3. **Recommended Improvements** — Non-blocking items the user may want to address (checklist format)

```markdown
# Rule Cleanup Report: <rule-name>

**Package:** <path>
**Date:** <today>

## Assessment

| | Before Cleanup | After Cleanup |
|---|---|---|
| **Score** | <old-score>/27 | <new-score>/27 |
| **Recommendation** | <old-recommendation> | <new-recommendation> |
| **Metadata (criterion 9)** | <old-meta-score>/3 | <new-meta-score>/3 |

The pre-cleanup assessment is preserved at `outputs/rule-assessment-pre-cleanup.md`.
The current assessment is at `outputs/rule-assessment.md`.

## Changes Made

### Blocking Issues Fixed

- [x] <what was fixed>
  **Before:** <old value or state>
  **After:** <new value or state>

### Required Metadata Added

- [x] <what was added>
  **Value:** <the value that was set>
  **Source:** <how the value was determined — inferred from X, default, or user-provided>

### Output Artifacts Generated

- [x] <artifact name> — <brief description of content>

## Recommended Improvements

Items that improve quality but are not required for release.

- [ ] <improvement>
  **What:** <what could be better>
  **Suggested fix:** <what to do>

## Summary

| Category | Count |
|----------|-------|
| Blocking issues fixed | N |
| Metadata fields added/fixed | N |
| Artifacts generated | N |
| Recommended improvements (not applied) | N |
| Tests passing | Yes/No |
```

### Step 8: Save the Report

Write the report to `<rule_package_dir>/outputs/cleanup-report.md`.

Print the full report to the conversation.

## Decision Rules for Ask vs Auto-Fix

| Situation | Action |
|-----------|--------|
| Value can be deterministically computed from existing rule content | **Auto-fix** |
| Value has a safe, standard default (e.g., `visibility: public`) | **Auto-fix with default** |
| Value requires judgment but a reasonable inference exists | **Auto-fix and note the inference in the report** |
| Value is personal/organizational (contributor name, reviewer) | **Ask user** |
| Value is ambiguous and wrong choice could misrepresent the rule | **Ask user** |
| Test failures after a fix | **Revert and report to user** |

## What This Skill Does NOT Do

- Does not add new test cases (workspace files) — this is left as a recommended improvement
- Does not rewrite audit queries or remediation logic
- Does not change the functional behavior of the rule
- Does not push or release the rule — that's the `orl-release-rule` skill's job
