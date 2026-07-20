---
name: gomboc_community_cap_orl_rules_push
description: >-
  Use when pushing a local rule package with `orl rules push` via Docker. Depends on:
  gomboc_community_know_orl_runtime_resolution.
---

# Capability: ORL Rules Push

## Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `rule_package` | yes | Absolute path to the rule package |
| `token_env` | no | Default `RULE_SERVICE_TOKEN` |

## Execution

```bash
cd "${RULE_PACKAGE}"
docker run --rm -v "${PWD}:/workspace" -w /workspace \
  -e RULE_SERVICE_TOKEN \
  gombocai/orl rules push .
```

## Constraints

- Never log the token.
- Callers must ensure tests passed first (`gomboc_community_cap_run_orl_test`).
- Prefer **`gomboc_community_task_release_rule`** for the full validate-then-push gate.
