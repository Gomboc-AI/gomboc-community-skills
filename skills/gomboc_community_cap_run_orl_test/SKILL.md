---
name: gomboc_community_cap_run_orl_test
description: >-
  Use when running `orl test .` against a rule package via Docker. Depends on:
  gomboc_community_know_orl_runtime_resolution.
---

# Capability: Run ORL Test

## Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `rule_package` | yes | Absolute path to the rule package directory |
| `double_run` | no | Cap input only — when `true`, run `orl test .` twice without restoring `workspace/` |

## Execution

Resolve runtime via **`gomboc_community_know_orl_runtime_resolution`**.

```bash
cd "${RULE_PACKAGE}"
docker run --rm -v "${PWD}:/workspace" -w /workspace gombocai/orl test .
```

When `double_run: true`, invoke the same command a second time. Never pass `--double-run` to `orl`.

## Output

```plain
ORL_TEST_RESULT_START
RULE_PACKAGE: <path>
RUNS: 1 | 2
PASS: yes | no
ORL_TEST_RESULT_END
```

## Constraints

- Do not invent CLI flags.
- Callers own iteration policy; this cap is one (or two) mechanical runs.
