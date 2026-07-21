---
name: gomboc_community_cap_orl_rules_pull
description: >-
  Use when pulling rules from the Gomboc Rules Service with `orl rules pull` (--search
  and/or --channel). Search via orl is a pull. Prefer MCP channel/rule lookup first when
  available. Depends on: gomboc_community_know_gomboc_mcp,
  gomboc_community_know_orl_runtime_resolution.
---

# Capability: ORL Rules Pull

There is no `orl rules search`. Matching remote rules uses `rules pull` with `--search` and/or `--channel`, which **downloads** rule packages.

## Prefer MCP

Follow **`gomboc_community_know_gomboc_mcp`** (including **Pagination**):

1. If refining by channel, call `get_channels` (metadata/query only).
2. **Channel pull** — call `get_channels_rules` with the channel `name`. **Paginate** with `page` / `perPage` until all `total` rules are fetched. When an item includes `body`, write it into `out_dir` as the local package / `.orl` and **skip Docker for that rule**. If an item omits `body`, call `get_rules` for that name before falling back.
3. **Search / known names** — for a search intent, prefer `search_rules` (**paginate** fully), then `get_rules` for any hit missing `body`. For each known rule **name**, call `get_rules` — the response includes the rule **`body`**. Write into `out_dir` and **skip Docker for that rule**.
4. Use Docker `orl rules pull` below **only** when MCP is unavailable, list/search/`get_rules` fails, or bodies are still missing **after full pagination** (and any `get_rules` follow-ups). Do **not** fall back because the channel/search result set is large or only the first page was retrieved.

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

## Query language

The `--search` flag uses prefix (Polish) notation:

| Operator | Description | Example |
|----------|-------------|---------|
| `(eq $.field "value")` | Exact equality | `(eq $.metadata.language "terraform")` |
| `(any "value" $.field)` | Deep search in field | `(any "CIS" $.classification)` |
| `(contains "value" $.field)` | String/array contains | `(contains "security" $.tags)` |
| `(matches "/regex/" $.field)` | Regex match | `(matches "/aws_s3/" $.name)` |
| `(and expr1 expr2 ...)` | All must be true | `(and (any "CIS" $.classification) ...)` |

## Constraints

- Never log the token.
- Prefer compound `--search` queries (classification + language + resource).
- Callers that need local-first + cache TTL use **`gomboc_community_task_resolve_existing_rules`**.
