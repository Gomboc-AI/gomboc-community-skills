---
name: gomboc_community_cap_orl_remediate
description: >-
  Use when running `orl remediate` (dry-run or apply) against a workspace via Docker.
  Depends on: gomboc_community_know_orl_runtime_resolution.
---

# Capability: ORL Remediate

## Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `workspace` | yes | Path to engineer code |
| `rule_path` | yes | Local rule package or rulespace path (`-r`) |
| `language` | yes | ORL language id |
| `dry_run` | no | Default `true` |

## Execution

Resolve runtime via **`gomboc_community_know_orl_runtime_resolution`**.

**Dry-run (default):**

```bash
docker run --rm -v "${PWD}:/workspace" -w /workspace gombocai/orl \
  remediate -d --language "${LANGUAGE}" -r "${RULE_PATH}" "${WORKSPACE}"
```

**Apply** (only after engineer confirmation upstream):

```bash
docker run --rm -v "${PWD}:/workspace" -w /workspace gombocai/orl \
  remediate --language "${LANGUAGE}" -r "${RULE_PATH}" "${WORKSPACE}"
```

## Output

```
ORL_REMEDIATE_RESULT_START
DRY_RUN: true | false
LANGUAGE: <id>
RULE_PATH: <path>
WORKSPACE: <path>
ORL_REMEDIATE_RESULT_END
```

## Constraints

- Default to dry-run.
- Never apply without upstream confirmation (flow/task responsibility).
