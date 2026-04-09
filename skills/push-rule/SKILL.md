---
name: push-rule
description: Push a completed ORL rule to the Gomboc Rules Service using a Personal Access Token. Validates the rule package and runs tests before pushing.
---

# Push Rule to Gomboc Rules Service

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

```bash
docker run -v "${PWD}:/workspace" gombocai/orl test .
```

All tests MUST pass before pushing. If tests fail, report the failures and stop. Do not push a rule with failing tests.

### 3. Push to Rules Service

Pass the `RULE_SERVICE_TOKEN` environment variable to the Docker container using `-e`:

```bash
docker run -v "${PWD}:/workspace" -e "${RULE_SERVICE_TOKEN}" gombocai/orl rules push .
```

The `-e RULE_SERVICE_TOKEN` flag forwards the host environment variable into the container. The user must have it set in their shell:

```bash
export RULE_SERVICE_TOKEN=your-personal-access-token
```

**Important**: Never log, display, or store the token value. If the token is not set, instruct the user to set it with the `export` command above.

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
