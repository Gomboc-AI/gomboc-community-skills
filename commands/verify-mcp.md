---
allowed-tools: Bash, Read, Glob, Grep, Agent, WebSearch, WebFetch
description: Verify the hosted Gomboc MCP server is configured and working — server ready plus a safe get_channels smoke call.
---

# Verify Gomboc MCP

Load **`gomboc_community_know_gomboc_mcp`** for setup and prefer/fallback rules. This command only checks connectivity.

## Pass criteria

1. MCP server `gomboc` is connected/ready and tools can be listed.
2. Smoke-call **`get_channels`** with `name: "default"` succeeds (HTTP/tool success, not a 404/auth error).

## Fail → guide setup

If either step fails, show the Cursor MCP config from the know skill:

- URL: `https://mcp.app.gomboc.ai/mcp`
- Header: `Authorization: Bearer ${env:GOMBOC_PAT}`
- Token: https://app.gomboc.ai/settings/tokens

Never log `GOMBOC_PAT`.

## Output

```
VERIFY_MCP_START
SERVER: ready | missing | error
SMOKE: get_channels(default) ok | fail
VERIFY_MCP_END
```

## Example Usage

```
/gomboc-community:verify-mcp
```
