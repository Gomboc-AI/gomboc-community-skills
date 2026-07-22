---
name: gomboc_community_know_orl_runtime_resolution
description: >-
  Use when resolving how to run ORL via the gombocai/orl Docker image in community
  workflows. No side effects.
---

# Know: ORL Runtime Resolution (Community)

All `orl` commands in this plugin run via Docker. Mount the working directory at `/workspace`.

## Invocation

```bash
docker run --rm -v "${PWD}:/workspace" -w /workspace gombocai/orl <command> [args...]
```

Pull/update the image when needed:

```bash
docker pull gombocai/orl
```

## Auth for Rules Service

Prefer host env **`GOMBOC_PAT`** (same token as hosted MCP / plugin userConfig). Never log the token value.

Resolve the host token in this order:

1. If `GOMBOC_PAT` is set → use it.
2. Else if `RULE_SERVICE_TOKEN` is set → use it, and **log a warning** that `RULE_SERVICE_TOKEN` is deprecated for community skills and callers should migrate to `GOMBOC_PAT` (do not document `RULE_SERVICE_TOKEN` in user-facing setup; keep this fallback for backward compatibility only).
3. Else → fail: ask the user to set `GOMBOC_PAT`.

The `orl` binary reads **`RULE_SERVICE_TOKEN`** inside the container. Always forward the resolved host token under that name:

```bash
# After resolving TOKEN from GOMBOC_PAT (or legacy RULE_SERVICE_TOKEN with warning):
docker run --rm -v "${PWD}:/workspace" -w /workspace \
  -e RULE_SERVICE_TOKEN="${TOKEN}" \
  gombocai/orl rules <pull|push> ...
```

Example resolution (never echo the secret):

```bash
if [ -n "${GOMBOC_PAT:-}" ]; then
  TOKEN="${GOMBOC_PAT}"
elif [ -n "${RULE_SERVICE_TOKEN:-}" ]; then
  echo "warning: RULE_SERVICE_TOKEN is deprecated; set GOMBOC_PAT instead" >&2
  TOKEN="${RULE_SERVICE_TOKEN}"
else
  echo "error: GOMBOC_PAT is not set" >&2
  exit 1
fi
```

## Rulespace

`orl rules pull` writes rule packages under `-o` (default `.`). Prefer a dedicated cache/rulespace such as `.gomboc/cache/rules/` or `.orl-rules/` so remediations can pass `-r <path>` or `--rulespace`.

## Constraints

- Always use absolute host paths in volume mounts when `PWD` is ambiguous.
- Do not invent CLI flags. Skill inputs (e.g. `double_run`) are not `orl` arguments.
- Prefer caps (`gomboc_community_cap_*`) over ad-hoc `docker run` in flows.
