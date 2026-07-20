---
name: gomboc_community_cap_orl_walk
description: >-
  Use when exploring AST structure with `orl walk` for a language and path via Docker.
  Depends on: gomboc_community_know_orl_runtime_resolution.
---

# Capability: ORL Walk

## Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `path` | yes | Directory or file to walk (usually `workspace`) |
| `language` | yes | ORL language id |

## Execution

```bash
docker run --rm -v "${PWD}:/workspace" -w /workspace gombocai/orl \
  walk "${PATH}" --language "${LANGUAGE}" ./workspace
```

Adjust the trailing path argument to match the package layout (often `./workspace` inside a rule package).

## Constraints

- Read-only exploration — do not modify files.
- Use results to inform query authoring in **`gomboc_community_task_write_orl_rule`**.
