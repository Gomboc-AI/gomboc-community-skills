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

Auth: resolve host token per **`gomboc_community_know_orl_runtime_resolution`** (`GOMBOC_PAT`, else legacy `RULE_SERVICE_TOKEN` with warning).

## Execution

```bash
cd "${RULE_PACKAGE}"
# TOKEN resolved per know_orl_runtime_resolution (prefer GOMBOC_PAT)
docker run --rm -v "${PWD}:/workspace" -w /workspace \
  -e RULE_SERVICE_TOKEN="${TOKEN}" \
  gombocai/orl rules push .
```

## Constraints

- Never log the token.
- Callers must ensure tests passed first (`gomboc_community_cap_run_orl_test`).
- Prefer **`gomboc_community_task_release_rule`** for the full validate-then-push gate.
