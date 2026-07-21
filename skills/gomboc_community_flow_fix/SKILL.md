---
name: gomboc_community_flow_fix
description: >-
  Use when scanning code and applying fixes — existing rules or generated ones; optional
  save/release. Entry point for /fix. Depends on: gomboc_community_flow_diagnose,
  gomboc_community_flow_apply_fix, gomboc_community_task_enrich_rule,
  gomboc_community_task_release_rule.
---

# Flow: Fix

Orchestrates the community in-context fix pipeline. Commands should load this skill and follow the phases below — do not duplicate long step docs in `commands/fix.md`.

## Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `target` | yes | File, directory, or glob |
| `concern` | no | e.g. encryption, least privilege |
| `framework` | no | e.g. CIS, NIST, PCI-DSS |

## Process

### Phase 1 — Diagnose

Execute **`gomboc_community_flow_diagnose`** for `target` (and filters).

**Ask the user which findings to fix** before continuing.

### Phase 2 — Apply

For each selected finding, execute **`gomboc_community_flow_apply_fix`**.

Show results after each fix. Continue to the next selected finding when fixing multiple.

### Phase 3 — Save / release (sole owner)

For newly generated rules from Phase 2 (apply Path B packages under `.orl-fixes/`):

1. Ask whether to save as reusable rules.
2. If yes: **`gomboc_community_task_enrich_rule`**, then ask about push.
3. If push: **`gomboc_community_task_release_rule`**.

Do **not** rely on **`gomboc_community_flow_apply_fix`** for enrich/release — that flow applies fixes only.

## Constraints

- Confirmation before any non-dry-run remediate (owned by apply-fix flow / remediate cap).
- Prefer skill delegation over inlined Docker/`orl` commands.
