---
name: gomboc_community_task_release_rule
description: >-
  Use when validating a rule package and pushing it to the Gomboc Rules Service. Depends
  on: gomboc_community_know_orl_runtime_resolution, gomboc_community_cap_run_orl_test,
  gomboc_community_cap_orl_rules_push.
---

# Task: Release Rule

You push completed ORL rule packages to the Gomboc Rules Service so they can be used for automated remediation.

## ORL via Docker

ORL is distributed as a Docker image. All `orl` commands MUST be run via Docker, mounting the current working directory into `/workspace`:

```bash
docker run -v "${PWD}:/workspace" gombocai/orl <command> [args...]
```

## Prerequisites

- Docker installed and running
- The `gombocai/orl` Docker image pulled: `docker pull gombocai/orl`
- The user must have a Gomboc Personal Access Token (PAT) set as `RULE_SERVICE_TOKEN` environment variable
- All rules pushed are **private to the user's account**

## Process

### 1. Verify Rule Package Structure

Check that the current directory contains a valid rule package:

```
<rule-name>/
├── <rule-name>.orl    # Main rule file (required)
├── test.orl           # Test definition (required)
├── workspace/         # Violation examples (required)
└── workspace_expected/  # Expected remediated output (required)
```

If any required files are missing, report the issue and stop.

### 2. Run Tests

Invoke **`gomboc_community_cap_run_orl_test`**. All tests MUST pass before pushing. If tests fail, report the failures and stop.

### 3. Push to Rules Service

Invoke **`gomboc_community_cap_orl_rules_push`**. Ensure `RULE_SERVICE_TOKEN` (or `GOMBOC_PAT` mapped per the know skill) is set. Never log the token.

### 4. Report Result

On success, report:
- The rule name that was pushed
- That it is now available in the user's private rules

On failure, report the error message from the ORL CLI.

## Querying Published Rules

After pushing, rules can be pulled with:

```bash
docker run -v "${PWD}:/workspace" -e "${RULE_SERVICE_TOKEN}" gombocai/orl rules pull --query '(contains $.name "rule-name")'
```

Or pull all rules for a specific language:

```bash
docker run -v "${PWD}:/workspace" -e "${RULE_SERVICE_TOKEN}" gombocai/orl rules pull --query '(eq finding.iacLanguage "terraform")'
```
