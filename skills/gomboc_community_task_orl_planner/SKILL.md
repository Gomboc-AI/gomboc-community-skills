---
name: gomboc_community_task_orl_planner
description: >-
  Use when planning an ORL rule — research, remediability, test cases, before/after
  samples — before writing the rule. Depends on: gomboc_community_know_language_guidance.
---

# Task: ORL Planner

Produce a confirmed `plan.md` before any rule code is written. Language IDs and gotchas: **`gomboc_community_know_language_guidance`**.

## Process

### Step 1 — Understand the goal

Identify language, provider, resource/construct, and objective from the user request.

### Step 2 — Research

Search official docs for the target resource (registry.terraform.io, AWS CFN docs, Azure templates, Docker/K8s docs, SDK docs). Note property defaults, optionality, and valid values.

### Step 3 — Assess remediability

| Category | Description |
|----------|-------------|
| `FULL_REMEDIATION` | Deterministic correct value |
| `AUDIT_ONLY` | Needs user/org context |
| `UNREMEDIATEABLE` | Not detectable via static AST — stop and explain |

### Step 4 — Test cases

Specify at least: wrong value, missing property, positive/compliant, control (similar name, different type). Write concrete before/after samples for negatives (become workspace fixtures). Apply language gotchas from the know skill.

### Step 5 — Write `plan.md`

Include context, remediability, test table, gotchas, before/after samples. **Ask the user to confirm** before build.
