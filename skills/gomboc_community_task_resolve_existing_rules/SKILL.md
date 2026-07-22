---
name: gomboc_community_task_resolve_existing_rules
description: >-
  Use when resolving a usable local rule path for a finding — local disk first, then
  cache, then MCP lookup, then orl rules pull. Depends on:
  gomboc_community_know_gomboc_mcp, gomboc_community_know_orl_runtime_resolution,
  gomboc_community_cap_orl_rules_pull.
---

# Task: Resolve Existing Rules

Remote discovery via `orl` is a **pull** (`orl rules pull --search`). There is no search-only `orl` command. Prefer hosted MCP lookup first per **`gomboc_community_know_gomboc_mcp`** (including **Pagination** for list/search tools).

## Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `language` | yes | ORL language id |
| `classification` | no | Policy / classification id |
| `resource` | no | Resource type hint |
| `cache_dir` | no | Default `.gomboc/cache/rules` |
| `cache_ttl_hours` | no | Default 24 |

## Process

1. **Local first** — if `/orl-rules/final/`, `.orl-rules/`, or `.orl-fixes/` exists, use `orl list_rules` / `rule_metadata` (via Docker per know skill) and match classification + language + resource.
2. **Cache** — if `cache_dir` has fresh metadata (`metadata.json` within TTL), reuse pulled packages.
3. **MCP fetch (prefer)** — if Gomboc MCP is available:
   - If a rule **name** is known, call `get_rules` per **`gomboc_community_know_gomboc_mcp`**. When `data.body` is present, write under `cache_dir` and treat as resolved (`SOURCE: mcp`).
   - If names are unknown, prefer `search_rules` and/or `get_channels_rules` — **paginate fully** (`page` / `perPage`) before concluding MCP cannot help. Materialize hits that include `body`; call `get_rules` for names missing `body`. Use `get_channels` / `get_classifications` / `search_classifications` (paginated) only to refine names/queries.
   - If MCP is still insufficient after full pagination and follow-up `get_rules`, continue to pull.
4. **Pull** — invoke **`gomboc_community_cap_orl_rules_pull`** with a compound `--search` query into `cache_dir`; refresh cache metadata (Docker only when MCP cannot supply bodies after the steps above).
5. **Report** match quality: existing / partial / none.

## Output

```
RULE_RESOLVE_START
STATUS: existing | partial | none
RULE_PATH: <path or none>
SOURCE: local | cache | mcp | pull
RULE_RESOLVE_END
```

## Constraints

- Never log tokens.
- Do not remediate here — callers use **`gomboc_community_cap_orl_remediate`**.
