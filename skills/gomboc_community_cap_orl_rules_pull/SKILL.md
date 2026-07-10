---
name: gomboc_community_cap_orl_rules_pull
description: >-
  Use when pulling rules from the Gomboc Rules Service with `orl rules pull` (--search
  and/or --channel). Search via orl is a pull. Depends on:
  gomboc_community_know_orl_runtime_resolution.
---

# Capability: ORL Rules Pull

There is no `orl rules search`. Matching remote rules uses `rules pull` with `--search` and/or `--channel`, which **downloads** rule packages.

## Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `out_dir` | yes | Host directory for pulled rules (`-o`) |
| `search` | no | Prefix-notation query for `--search` |
| `channel` | no | Channel name for `--channel` |
| `token_env` | no | Default `RULE_SERVICE_TOKEN` |

## Execution

```bash
docker run --rm -v "${PWD}:/workspace" -w /workspace \
  -e RULE_SERVICE_TOKEN \
  gombocai/orl rules pull -o "${OUT_DIR}" \
  --search '(and (any "<classification>" $.classification) (eq $.metadata.language "<lang>"))'
```

Or by channel:

```bash
docker run --rm -v "${PWD}:/workspace" -w /workspace \
  -e RULE_SERVICE_TOKEN \
  gombocai/orl rules pull -o "${OUT_DIR}" --channel default
```

## Output

```
ORL_RULES_PULL_RESULT_START
OUT_DIR: <path>
MATCH_COUNT: <n or unknown>
ORL_RULES_PULL_RESULT_END
```

## Constraints

- Never log the token.
- Prefer compound `--search` queries (classification + language + resource).
- Callers that need local-first + cache TTL use **`gomboc_community_task_resolve_existing_rules`**.
