---
name: gomboc_community_task_run_orl_test_loop
description: >-
  Use when running orl test and iterating on a rule package until tests pass or the
  attempt budget is exhausted. Depends on: gomboc_community_cap_run_orl_test.
---

# Task: Run ORL Test Loop

## Inputs

| Parameter | Required | Description |
|-----------|----------|-------------|
| `rule_package` | yes | Absolute path to the rule package directory (same name as **`gomboc_community_cap_run_orl_test`**) |
| `max_attempts` | no | Default 5 |

## Process

1. Invoke **`gomboc_community_cap_run_orl_test`** with the same `rule_package`.
2. On failure, inspect diffs/output, adjust rule or expected fixtures, retry.
3. Optionally set `double_run: true` on a final passing run for idempotency.
4. Stop after `max_attempts` and report remaining failures.

## Constraints

- Never pass `--double-run` to the CLI.
- Do not apply remediations to engineer code here — use **`gomboc_community_cap_orl_remediate`**.
