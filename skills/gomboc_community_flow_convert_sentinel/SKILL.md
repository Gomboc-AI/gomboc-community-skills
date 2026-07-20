---
name: gomboc_community_flow_convert_sentinel
description: >-
  Use when converting a HashiCorp Sentinel policy into one or more ORL rules. Depends on:
  gomboc_community_know_orl_runtime_resolution, gomboc_community_know_sentinel_conversion,
  gomboc_community_know_language_guidance, gomboc_community_task_setup_rule_workspace,
  gomboc_community_task_write_orl_rule, gomboc_community_task_run_orl_test_loop,
  gomboc_community_task_enrich_rule, gomboc_community_task_release_rule.
---

# Flow: Convert Sentinel

Convert a HashiCorp Sentinel policy into one or more tested ORL rules. Paradigm, strategy tables, and conversion limits live in **`gomboc_community_know_sentinel_conversion`** — load that first; do not restate it here.

## Inputs

- Sentinel policy URL or local `.sentinel` path
- Optional: example Terraform / Sentinel mock data

## Process

### Step 1 — Retrieve and analyze

Fetch or read the policy. Identify target resources/attributes, enforcement logic, severity, and imports (`tfplan` / `tfstate` / `tfconfig` / `tfrun`).

### Step 2 — Assess strategy

Using **`gomboc_community_know_sentinel_conversion`**, choose fix vs audit-only (or unconvertible). **Present the plan to the user and confirm** before building.

### Step 3 — Decompose

One ORL rule per attribute concern; separate wrong-value vs missing-attribute. Name: `gomboc-ai/terraform/<provider>/<resource>/<requirement>`.

### Step 4 — Build package(s)

For each sub-rule:

1. **`gomboc_community_task_setup_rule_workspace`** (map Sentinel mocks to fixtures when provided; audit-only → identical workspace/expected).
2. Load **`gomboc_community_know_language_guidance`** (Terraform).
3. **`gomboc_community_task_write_orl_rule`**.
4. **`gomboc_community_task_run_orl_test_loop`**.

### Step 5 — Enrich

**`gomboc_community_task_enrich_rule`**, plus provenance annotations when applicable:

- `gomboc-ai/source: "sentinel"`
- `gomboc-ai/sentinel-policy: "<original-policy-name>"`

### Step 6 — Optional release

Ask whether to push. If yes → **`gomboc_community_task_release_rule`**.

## Reference examples

`references/examples/sentinel/` — worked `require-most-recent-ami-version` conversion.

## Constraints

- Be transparent about unconvertible checks (see know skill).
- Prefer tasks/caps; no inlined Docker/`orl` recipes.
