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

Forward the host token into the container (never log the value):

```bash
docker run --rm -v "${PWD}:/workspace" -w /workspace \
  -e RULE_SERVICE_TOKEN \
  gombocai/orl rules <pull|push> ...
```

Community docs also refer to `GOMBOC_PAT` in plugin userConfig — map it to `RULE_SERVICE_TOKEN` for the container when the host only has `GOMBOC_PAT` set.

## Rulespace

`orl rules pull` writes rule packages under `-o` (default `.`). Prefer a dedicated cache/rulespace such as `.gomboc/cache/rules/` or `.orl-rules/` so remediations can pass `-r <path>` or `--rulespace`.

## Constraints

- Always use absolute host paths in volume mounts when `PWD` is ambiguous.
- Do not invent CLI flags. Skill inputs (e.g. `double_run`) are not `orl` arguments.
- Prefer caps (`gomboc_community_cap_*`) over ad-hoc `docker run` in flows.
