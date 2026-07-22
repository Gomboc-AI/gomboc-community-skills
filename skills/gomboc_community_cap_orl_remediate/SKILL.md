---
name: gomboc_community_cap_orl_remediate
description: >-
  Use when running `orl remediate` (dry-run or apply) against a workspace via Docker,
  writing a report and submitting it to integrations (non-blocking). Depends on:
  gomboc_community_know_orl_runtime_resolution, gomboc_community_know_gomboc_mcp.
---

# Capability: ORL Remediate

## Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `workspace` | yes | Path to engineer code |
| `rule_path` | yes | Local rule package or rulespace path (`-r`) |
| `language` | yes | ORL language id |
| `dry_run` | no | Default `true` |
| `report_out` | no | Host path for `--out` (default `.orl-report.yaml`) |

## Execution

Resolve runtime via **`gomboc_community_know_orl_runtime_resolution`**.

Always pass **`--include-location-info`** and **`--out`** so the report includes finding locations (required for integrations payloads).

**Dry-run (default):**

```bash
docker run --rm -v "${PWD}:/workspace" -w /workspace gombocai/orl \
  remediate -d --language "${LANGUAGE}" -r "${RULE_PATH}" \
  --include-location-info --out "/workspace/${REPORT_OUT}" \
  "${WORKSPACE}"
```

**Apply** (only after engineer confirmation upstream):

```bash
docker run --rm -v "${PWD}:/workspace" -w /workspace gombocai/orl \
  remediate --language "${LANGUAGE}" -r "${RULE_PATH}" \
  --include-location-info --out "/workspace/${REPORT_OUT}" \
  "${WORKSPACE}"
```

Default `REPORT_OUT` is `.orl-report.yaml` (container path `/workspace/.orl-report.yaml`).

### Submit report (required, non-blocking)

After **every** remediate (dry-run or apply), submit the report. Prefer MCP `post_external_run_event` per **`gomboc_community_know_gomboc_mcp`** when you can build a valid `accountId` + `event` payload from the report; otherwise use the script (never invent tool args). Submission must **not** fail the remediate workflow.

```bash
python3 "${PLUGIN_ROOT}/scripts/integrations/submit_orl_report.py" \
  --report "${PWD}/${REPORT_OUT}" --workspace "${PWD}" \
  --branch "$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')" --duration 0
```

`PLUGIN_ROOT` is the community-skills plugin / repo root (where `scripts/integrations/` lives). Auth uses **`GOMBOC_PAT`**. Missing SDK, token, or network → skip with a warning; exit must not block the caller.

## Output

```
ORL_REMEDIATE_RESULT_START
DRY_RUN: true | false
LANGUAGE: <id>
RULE_PATH: <path>
WORKSPACE: <path>
REPORT_OUT: <path>
SUBMIT: mcp | script | skipped
ORL_REMEDIATE_RESULT_END
```

## Constraints

- Default to dry-run.
- Never apply without upstream confirmation (flow/task responsibility).
- Never omit `--include-location-info` or `--out` when remediating.
- Never log tokens.
