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
3. If a matching tool exists, call it.
4. If the response is **enough to proceed**, use it and skip the Docker/`orl` path for that step.
5. If MCP is unavailable, the tool is missing, the call fails, or the payload is insufficient → fall back to the existing Docker/`orl` / local path.

Do not invent tool names. Soft map entries may go stale; discovery wins.

## Soft capability map (today)

| Intent | Prefer MCP tool(s) | Fall back when MCP insufficient |
|--------|--------------------|----------------------------------|
| Channel lookup | `get_channels` (`name` optional; use `"default"` for smoke) | `gomboc_community_cap_orl_rules_pull` with `--channel` |
| Rule metadata by name | `get_rules` (`name` required) | `gomboc_community_cap_orl_rules_pull` with `--search` |
| Classification lookup / tree | `get_classifications` (`name` required; optional `parents` / `children` / `expandChildren`) | Local `references/` / `classifications.txt` |
| Post ORL external run event | `post_external_run_event` (`accountId` + `event`) | `scripts/integrations/submit-orl-report.mjs` (HTTP) |

**Not on MCP today** (keep Docker/`orl`): remediate, walk, test, rules push, package download. When discovery later shows tools for those intents, prefer MCP under the same rules.

### Enough to proceed (rules)

`get_rules` / `get_channels` are metadata lookups, not guaranteed package downloads.

- **Enough**: response identifies the rule/channel and the caller can continue without pulling (e.g. confirm existence, refine search, enrich metadata).
- **Not enough**: caller needs a local rule package path for remediate/test → fall back to **`gomboc_community_cap_orl_rules_pull`**.

## Safety

Same gates as ORL remediate caps for any future MCP tool that changes code: dry-run/preview first; apply only after engineer confirmation; never log tokens. Stricter CRUD rules come later.

## Constraints

- Hosted URL only for this skill family (`https://mcp.app.gomboc.ai/mcp`) — do not assume local Docker MCP.
- Prefer this know skill over hardcoding MCP URLs/tool lists inside flows.
- Cap/task/flow skills still own their Docker/`orl` execution; this skill only defines when to try MCP first.
