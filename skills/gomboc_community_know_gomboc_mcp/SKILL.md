---
name: gomboc_community_know_gomboc_mcp
description: >-
  Use when configuring or calling the hosted Gomboc MCP server, deciding prefer-MCP
  vs Docker/orl fallback, or verifying MCP setup. No side effects by itself — callers
  invoke MCP tools. Underlying capability for rules lookup, classifications, channels,
  and external-run reporting.
---

# Know: Gomboc MCP (Hosted)

Hosted MCP at `https://mcp.app.gomboc.ai/mcp` (Cursor server id typically `gomboc`). Prefer MCP when available for matching intents; otherwise fall back to Docker/`orl` caps and local references. MCP tools change over time — always re-discover.

## Setup (Cursor)

Require `GOMBOC_PAT` in the environment. Add to Cursor MCP config (`~/.cursor/mcp.json` or project MCP settings):

```json
{
  "mcpServers": {
    "gomboc": {
      "url": "https://mcp.app.gomboc.ai/mcp",
      "headers": {
        "Authorization": "Bearer ${env:GOMBOC_PAT}"
      }
    }
  }
}
```

Get a token at https://app.gomboc.ai/settings/tokens. Never log the token.

## Availability

MCP is **available** when the `gomboc` server is connected/ready and tools can be listed. If missing, errored, or unauthorized → treat as unavailable and use Docker/`orl` (or local refs) without blocking the user.

Verify with **`/gomboc-community:verify-mcp`** (smoke: `get_channels` with `name: "default"`).

## Prefer MCP → fall back

For any skill step that maps to an MCP intent:

1. Discover tools on server `gomboc` (list tools + schemas).
2. Match intent via the soft map below **and** live tool names/descriptions.
3. If a matching tool exists, call it. If the schema exposes `page` / `perPage` (or equivalent), **paginate fully** before deciding MCP is insufficient — see **Pagination** below.
4. If the response is **enough to proceed**, use it and skip the Docker/`orl` path for that step.
5. If MCP is unavailable, the tool is missing, the call fails, or the **fully paginated** payload is still insufficient → fall back to the existing Docker/`orl` / local path.

Do not invent tool names. Soft map entries may go stale; discovery wins.

## Pagination (required)

Many list/search tools are **paged**. Do **not** treat the first page as the full result set, and do **not** fall back to Docker solely because a first page is smaller than `total`.

When a discovered tool schema includes `page` and/or `perPage` (or equivalent):

1. Call with an explicit `page` (start at `1`) and a reasonable `perPage` (e.g. `50`–`100` unless the schema constrains it).
2. Read `total` (or equivalent) and the current page’s items from the response.
3. **Loop**: increment `page` and call again until every item is fetched (`page * perPage >= total`, or a page returns fewer items than `perPage` / an empty list).
4. Only after the full set is collected may you materialize packages or decide MCP is insufficient.

**Never** skip remaining pages and switch to Docker/`orl` just because the result set is large. Volume is not a fallback reason when MCP already returns usable payloads (e.g. rule `body`).

Paged tools known today (re-check via discovery): `get_channels_rules`, `search_rules`, `search_channels`, `search_classifications`.

## Soft capability map (today)

| Intent | Prefer MCP tool(s) | Fall back when MCP insufficient |
|--------|--------------------|----------------------------------|
| Channel lookup | `get_channels` (`name` optional; use `"default"` for smoke) | Local channel name / Docker `--channel` only if MCP channel tools fail |
| List / pull rules in a channel | `get_channels_rules` (`name`; **paginate** `page` / `perPage`) — items often include `body` | Docker `orl rules pull --channel` via **`gomboc_community_cap_orl_rules_pull`** only if MCP list/fetch fails or bodies missing after full pagination |
| Search rules | `search_rules` (**paginate** `page` / `perPage`; optional `query` / `filters` / `iacLanguage`) — then `get_rules` by name if body omitted | Docker `orl rules pull --search` via **`gomboc_community_cap_orl_rules_pull`** |
| Fetch / pull rule by name | `get_rules` (`name` required) — response includes rule `body` | Docker `orl rules pull` via **`gomboc_community_cap_orl_rules_pull`** |
| Classification lookup / tree | `get_classifications` (`name` required; optional `parents` / `children` / `expandChildren`) | Local `references/` / `classifications.txt` |
| Search classifications | `search_classifications` (**paginate** `page` / `perPage`) | Local `references/` / `classifications.txt` |
| Search channels | `search_channels` (**paginate** `page` / `perPage`) | Docker/`orl` channel name only if MCP search fails |
| Post ORL external run event | `post_external_run_event` (`accountId` + `event`) | `scripts/integrations/submit-orl-report.mjs` (HTTP) |

**Not on MCP today** (keep Docker/`orl`): remediate, walk, test, rules push. When discovery later shows tools for those intents, prefer MCP under the same rules (including pagination when present).

### Enough to proceed (rules)

- **`get_rules`**: **Enough** when `status` is success and `data.body` (or equivalent rule payload) is present — materialize the local `.orl` / package from that payload; do **not** fall back to Docker for that name.
- **`get_channels_rules`**: **Enough** for channel sync when, **after full pagination**, each needed rule has a `body` (or you successfully follow up with `get_rules` for any name missing a body). Materialize every page’s rules locally; do **not** fall back to Docker because `total` is large or only page 1 was fetched.
- **`search_rules` / `search_channels` / `search_classifications`**: **Enough** only after **full pagination**. Use returned names/metadata to drive `get_rules` / further lookups; if search hits omit `body`, call `get_rules` per name before considering Docker.
- **`get_channels`**: channel metadata + query only — enough to refine channel name / search; **not** enough by itself to write rule packages. Next step: paginate `get_channels_rules` (or `search_rules` + `get_rules`), not Docker-first bulk pull.
- **Not enough / fall back to Docker**: MCP unavailable; list/search tool missing; a call fails; after **full pagination**, bodies still missing and `get_rules` also fails/omits body.

## Safety

Same gates as ORL remediate caps for any future MCP tool that changes code: dry-run/preview first; apply only after engineer confirmation; never log tokens. Stricter CRUD rules come later.

## Constraints

- Hosted URL only for this skill family (`https://mcp.app.gomboc.ai/mcp`) — do not assume local Docker MCP.
- Prefer this know skill over hardcoding MCP URLs/tool lists inside flows.
- Cap/task/flow skills still own their Docker/`orl` execution; this skill only defines when to try MCP first (and how to paginate).
- Do not invent pagination semantics — follow the live tool schema and response fields (`page`, `perPage`, `total`, item arrays).
