# Gomboc ORL Community Skills

A Claude Code plugin for remediating your code deterministically with Gomboc Open Remediation Language (ORL). Enables creating, testing, and publishing ORL (Open Remediation Language) rules for Infrastructure as Code. Supports Terraform, CloudFormation YAML, and Bicep. Provides skills for remediating code with available rules.

## Prerequisites

- [Claude Code](https://claude.com/claude-code) CLI installed
- [Docker](https://docs.docker.com/get-docker/) installed and running
- ORL Docker image: `docker pull gombocai/orl` ([Docker Hub](https://hub.docker.com/r/gombocai/orl))
- A Gomboc Personal Access Token (PAT) for pushing rules (optional)

## ORL via Docker

All ORL commands run via the `gombocai/orl` Docker image. The current directory is mounted into the container at `/workspace`:

```bash
docker run -v "${PWD}:/workspace" gombocai/orl <command>
```

Examples:

```bash
docker run -v "${PWD}:/workspace" gombocai/orl test .
docker run -v "${PWD}:/workspace" gombocai/orl walk workspace --language terraform ./workspace
docker run -v "${PWD}:/workspace" gombocai/orl remediate -d --language terraform -r . ./workspace
```

To push rules, pass your token via the `-e` flag:

```bash
docker run -v "${PWD}:/workspace" -e RULE_SERVICE_TOKEN gombocai/orl rules push .
```

## Installation

### From the marketplace

```bash
claude plugin marketplace add Gomboc-AI/gomboc-community-skills
claude plugin install gomboc-orl-community@gomboc-community-marketplace
```

### From local path

```bash
claude plugin install /path/to/community-skills
```

## Skills

| Skill | Description |
|-------|-------------|
| `plan-rule` | Analyze requirements, identify test cases, and create a plan for an ORL rule |
| `build-rule` | Create workspace files, write the ORL rule, and test it |
| `add-metadata` | Add basic metadata (name, description, classifications, provider) to a rule |
| `push-rule` | Push a completed rule to the Gomboc Rules Service |

## Quick Start

Use the `/gomboc-orl-community:create-rule` command to run the full workflow:

```
/gomboc-orl-community:create-rule Ensure all AWS S3 buckets have server-side encryption enabled using Terraform
```

Or invoke individual skills:

```
/gomboc-orl-community:plan-rule
/gomboc-orl-community:build-rule
/gomboc-orl-community:add-metadata
/gomboc-orl-community:push-rule
```

## Supported Languages

- **Terraform** (HCL) — Full template helper support (`aResource`, `anAttribute`, `aMissingAttribute`, etc.)
- **CloudFormation YAML** — Raw tree-sitter queries for YAML AST
- **Bicep** — Raw tree-sitter queries for Bicep AST

## Publishing Rules

To push rules to your Gomboc Community Edition account:

1. Set your Personal Access Token: `export RULE_SERVICE_TOKEN=your-pat-here`
2. Run `/gomboc-orl-community:push-rule` from your rule directory

## Rule Package Structure

Each rule is a self-contained directory:

```
my-rule/
├── my-rule.orl            # Main rule file
├── test.orl               # Test definition
├── workspace/             # IaC files with violations
└── workspace_expected/    # IaC files after remediation
```

## License

MIT
