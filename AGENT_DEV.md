# Agent Development Guide — Gomboc Community Skills

Load this file when **auditing**, **creating**, or **updating** skills in `gomboc-community-skills`.

This document captures contributor conventions for the layered `gomboc_community_*` skill architecture — including flow/task/cap/know roles, manifest registration, and command entry points.

---

## How to Use This Guide

| Task | Start here |
|------|------------|
| Audit an existing skill | [Skill audit checklist](#skill-audit-checklist) |
| Add a new workflow or skill | [Creating a new skill](#creating-a-new-skill) |
| Refactor or extend a skill | [Updating an existing skill](#updating-an-existing-skill) |
| Understand layering | [Skill architecture](#skill-architecture) |

**Canonical skill location:** `skills/<skill-name>/SKILL.md`

**Reference docs:** `references/` (ORL syntax, classifications, language AST patterns)

---

## Skill Architecture

Community skills use one layered family. Do not introduce bare kebab-case skill names.

### Layered `gomboc_community_*` skills

| Prefix | Role | Executes CLI? | Example |
|--------|------|---------------|---------|
| `gomboc_community_flow_*` | Top-level orchestrator; state machine across tasks | No — delegates only | `gomboc_community_flow_fix` |
| `gomboc_community_task_*` | Stateful workflow step; may call caps | Via caps, not raw shell inventing flags | `gomboc_community_task_enrich_rule` |
| `gomboc_community_cap_*` | Stateless, mechanical single operation | Yes — one bounded action | `gomboc_community_cap_orl_remediate` |
| `gomboc_community_know_*` | Reference knowledge; no side effects | No | `gomboc_community_know_orl_runtime_resolution` |

**Delegation rule:** Tasks call capabilities. Flows call tasks (and other flows when composing). Flows do not invent CLI flags.

**Prefix rule:** Always use the `gomboc_community_` prefix for skill directory names and frontmatter `name:` values.

**ORL rules discovery:** Remote matching uses `orl rules pull --search` (or `--channel`). That **downloads** rules — there is no separate `orl` search command. Do not add a `…_rules_search` cap unless you introduce Rules Service API discovery that does not pull files.

---

## SKILL.md Format

Every skill is a **directory** with a `SKILL.md` file.

### Frontmatter (required)

```yaml
---
name: gomboc_community_task_example
description: >-
  Use when <trigger / situation>. Include Depends on: <skill-a>, <skill-b>
  when the skill requires others. Omit Depends on when none.
---
```

**Description rules:**

- Start with `Use when …` so agents can match the skill to the user's intent.
- Keep the trigger concrete (what the engineer is trying to do), not a restatement of the skill type.
- End with `Depends on: ...` listing direct skill dependencies (not transitive).
- Omit `Depends on:` when the skill has no hard dependencies.
- Keep under ~500 characters where possible; use `>-` folded scalar for multi-line.

### Body structure (recommended)

```markdown
# Task: Example

One-paragraph purpose and when to use vs sibling skills.

## Inputs
| Parameter | Required | Description |

## Process
### Step 1 — ...

## Output Block
(structured block when handing off)

## Constraints
- Never ...
```

---

## Registration Checklist

After creating or renaming a skill, register it in **all four** CLI manifests:

| CLI | Manifest path | Path format |
|-----|---------------|-------------|
| Claude Code | `.claude-plugin/plugin.json` | `"./skills/<name>/SKILL.md"` |
| Cursor | `.cursor-plugin/plugin.json` | `"./skills/<name>/"` |
| OpenAI Codex | `.codex-plugin/plugin.json` | Skills dir or explicit list |
| Gemini | `gemini-extension.json` | Match Claude pattern / extension docs |

**Verification:** Frontmatter `name:` must match the directory name.

### Commands (optional entry points)

Commands live in `commands/`:

- `commands/<name>.md` — Claude-style markdown command

**Single entry point:** Put full orchestration in the **flow skill**. Commands list the skill sequence and user gates only — do not duplicate long process docs in both places.

---

## Current Skill Inventory

### Flows

| Skill | Purpose |
|-------|---------|
| `gomboc_community_flow_fix` | `/fix` — diagnose → apply → optional save/release |
| `gomboc_community_flow_create_rule` | `/create-rule` — plan → build → review → enrich → release |
| `gomboc_community_flow_diagnose` | Classification-driven scan + rule coverage |
| `gomboc_community_flow_apply_fix` | Existing-rule or generate-rule apply path |
| `gomboc_community_flow_build_rule` | Zero-context / planned rule package authoring |
| `gomboc_community_flow_review_rule` | Pre-release compliance fix + report |
| `gomboc_community_flow_convert_sentinel` | Sentinel → ORL conversion pipeline |

### Tasks

| Skill | Purpose |
|-------|---------|
| `gomboc_community_task_orl_planner` | Plan before build |
| `gomboc_community_task_enrich_rule` | Community metadata enrichment |
| `gomboc_community_task_release_rule` | Validate + `orl rules push` |
| `gomboc_community_task_setup_rule_workspace` | Create package dirs + fixtures |
| `gomboc_community_task_write_orl_rule` | Author `.orl` + `test.orl` |
| `gomboc_community_task_run_orl_test_loop` | Test / iterate until pass |
| `gomboc_community_task_resolve_existing_rules` | Local-first → cache → pull |

### Caps

| Skill | Purpose |
|-------|---------|
| `gomboc_community_cap_run_orl_test` | `orl test .` |
| `gomboc_community_cap_orl_remediate` | `orl remediate` (dry-run default) |
| `gomboc_community_cap_orl_walk` | `orl walk` AST explore |
| `gomboc_community_cap_orl_rules_pull` | `orl rules pull` (`--search` / `--channel`) |
| `gomboc_community_cap_orl_rules_push` | `orl rules push` |

### Know

| Skill | Purpose |
|-------|---------|
| `gomboc_community_know_gomboc_mcp` | Hosted MCP setup; prefer MCP when available; soft capability map + discovery |
| `gomboc_community_know_orl_runtime_resolution` | Docker `gombocai/orl` invocation |
| `gomboc_community_know_language_guidance` | Per-language ORL authoring notes |
| `gomboc_community_know_sentinel_conversion` | Sentinel vs ORL paradigm |
| `gomboc_community_know_release_checklist` | Release-readiness criteria |

---

## Pipelines

### `/fix` → `gomboc_community_flow_fix`

```
gomboc_community_flow_diagnose
  → gomboc_community_flow_apply_fix          # fix only
  → (optional) gomboc_community_task_enrich_rule   # flow_fix Phase 3 owns save/release
  → (optional) gomboc_community_task_release_rule
```

### `/create-rule` → `gomboc_community_flow_create_rule`

```
gomboc_community_task_orl_planner
  → gomboc_community_flow_build_rule
  → gomboc_community_flow_review_rule
  → gomboc_community_task_enrich_rule
  → gomboc_community_task_release_rule
```

### `/convert-sentinel` → `gomboc_community_flow_convert_sentinel`

```
(analyze → strategy → build via shared tasks)
  → (optional) gomboc_community_task_release_rule
```

---

## Skill Audit Checklist

### Structure and discovery

- [ ] Skill is `skills/<name>/SKILL.md` (directory layout)
- [ ] Registered in Claude + Cursor manifests (and Codex/Gemini as applicable)
- [ ] `name:` in frontmatter matches directory name
- [ ] `description` starts with `Use when …` and includes accurate `Depends on:` or omits it when none
- [ ] Disambiguation: skill states when to use sibling skills instead

### Orchestration correctness

- [ ] Flow skills delegate to tasks; tasks delegate to caps
- [ ] No invented CLI flags (skill inputs ≠ `orl` arguments)
- [ ] ORL runtime resolved via `gomboc_community_know_orl_runtime_resolution`
- [ ] MCP prefer/fallback via `gomboc_community_know_gomboc_mcp` when the step maps to an MCP intent
- [ ] Engineer confirmation before any non-dry-run remediate
- [ ] Remote rule discovery prefers MCP lookup when available, then `gomboc_community_cap_orl_rules_pull` (pull-with-search), not a fake search-only `orl` command

### Artifacts

- [ ] Outputs under workspace paths documented (e.g. `.orl-fixes/`, `.gomboc/` if used)
- [ ] Token env var (`GOMBOC_PAT`) never logged

---

## Creating a New Skill

### 1. Choose the skill type

| Need | Create |
|------|--------|
| New multi-step user workflow | `gomboc_community_flow_<domain>` + tasks + caps |
| Reusable workflow step | `gomboc_community_task_<action>` |
| Single CLI/file operation | `gomboc_community_cap_<verb>` |
| Static reference | `gomboc_community_know_<topic>` |

### 2. Scaffold

```bash
mkdir -p skills/gomboc_community_task_my_feature
```

Write `SKILL.md` with frontmatter, inputs, numbered steps, output block, constraints.

### 3. Wire dependencies

- List direct dependencies in `Depends on:`.
- Reference dependency skills by name in the body; do not inline their full content.
- Register in all manifests.
- Update this inventory table and `README.md`.

### 4. Version

Per plugin manifests:

- **Patch:** Prompt fixes, docs, no interface change
- **Minor:** New skill or command; new optional output field
- **Major:** Breaking rename, removed skills, or command argument changes

Use `bin/version bump major|minor|patch` (or `set`) to keep marketplace + plugin files in sync.

---

## Updating an Existing Skill

### Safe (patch)

- Clarify steps, fix incorrect CLI examples
- Add edge cases and constraints
- Improve disambiguation vs sibling skills
- Fix manifest registration

### Breaking (minor/major)

- Rename structured output fields
- Change command argument semantics
- Split a monolithic skill into flow/task/cap layers
- Rename skills referenced by commands

When splitting orchestration:

1. Move canonical logic to the generic task or cap.
2. Leave the flow as a thin orchestrator.
3. Update `Depends on:` chains and command docs.
4. Bump version appropriately (rename without aliases = major).

---

## Common Pitfalls

| Mistake | Correct approach |
|---------|------------------|
| Bare kebab skill (`diagnose`) | Use `gomboc_community_flow_diagnose` (or task/cap/know) |
| Missing `gomboc_community_` prefix | Directory and frontmatter `name:` must use `gomboc_community_*` |
| `orl rules search` | Does not exist — use `orl rules pull --search` |
| `orl test . --double-run` | Run `orl test .` twice; `double_run` is a cap input only |
| Flow runs `orl remediate` without confirm | Cap defaults to dry-run; apply only after engineer approval |
| Duplicate command + flow docs | Flow skill is canonical; command lists sequence only |
| Flat `skills/foo.md` | Directory `skills/foo/SKILL.md` + manifest registration |
| Inlining Docker/`orl` in every skill | Depend on `gomboc_community_know_orl_runtime_resolution` + caps |
| Hardcoding MCP tool lists | Depend on `gomboc_community_know_gomboc_mcp`; re-discover tools; soft map may be stale |

---

## Testing Contributor Changes

- Walk skill steps against a sample workspace.
- Confirm structured output blocks (if any) parse correctly.
- Verify delegation (flow → task → cap) has no skipped confirmation gates.
- Load the plugin in an agent and confirm skills appear under the new names.

### Prerequisites

- Docker for `gombocai/orl` (see `gomboc_community_know_orl_runtime_resolution`)
- `GOMBOC_PAT` for Rules Service pull/push (map for `orl` per `gomboc_community_know_orl_runtime_resolution`)
