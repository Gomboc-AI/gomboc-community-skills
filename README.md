# Gomboc ORL Community Skills

A Claude Code plugin for scanning, fixing, and creating ORL (Open Remediation Language) rules across IaC, containers, orchestration, and application code. Any `--language` value supported by your `gombocai/orl` image applies — see [ORL supported languages](references/orl-supported-languages.md).

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
claude plugin install gomboc-community@gomboc-community-marketplace
```

### From local path

```bash
claude plugin install /path/to/community-skills
```

## Commands

### `/fix` — Scan and Fix Code

Scan source code for security anti-patterns and compliance gaps using the ORL classification policy corpus, then apply fixes — using existing rules or generating new ones on the fly. Optionally save fixes as reusable rules.

```
/gomboc-community:fix main.tf — check encryption
/gomboc-community:fix ./infrastructure/ — security review
/gomboc-community:fix Dockerfile
/gomboc-community:fix k8s/ — least privilege
/gomboc-community:fix src/api/ — prevent code injection
/gomboc-community:fix . — CIS compliance check
```

**Workflow:** diagnose → select issues → apply fixes → optionally save as rules

### `/create-rule` — Create a Rule from Scratch

Define a security or compliance policy and build a complete ORL rule package with tests.

```
/gomboc-community:create-rule Ensure all AWS S3 buckets have server-side encryption enabled using Terraform
/gomboc-community:create-rule Ensure Dockerfiles use pinned image digests instead of mutable tags
/gomboc-community:create-rule Ensure Kubernetes Deployments set runAsNonRoot in securityContext
```

**Workflow:** plan → build → add metadata → optionally push

## Skills

| Skill | Description |
|-------|-------------|
| `diagnose` | Classification-driven analyzer — detects language, loads matching policies, walks the AST, reports prioritized findings |
| `apply-fix` | Applies a fix using an existing ORL rule or generates a new one, with optional save-as-rule |
| `plan-rule` | Analyze requirements, identify test cases, and create a plan for an ORL rule |
| `build-rule` | Create workspace files, write the ORL rule, and test it |
| `add-metadata` | Add basic metadata (name, description, classifications, provider) to a rule |
| `push-rule` | Push a completed rule to the Gomboc Rules Service |
| `cleanup-rule` | Evaluate a rule package against release standards and produce a detailed remediation checklist |

## Supported Languages

ORL language IDs are defined by the CLI. The canonical enumerated list for this repo’s baseline is in [references/orl-supported-languages.md](references/orl-supported-languages.md). Confirm the exact set for your Docker image with:

```bash
docker run gombocai/orl language
```

## Classification-Driven Analysis

The `/fix` command uses the ORL classification policy corpus (`/orl-rules/final/classifications/policies/`) as its knowledge base. Each classification YAML defines:

- What security or compliance policy to enforce
- Which languages and resource types it applies to
- Impact and risk scores for prioritization
- Compliance framework mappings (CIS, NIST CSF, PCI-DSS, AWS Well-Architected, etc.)

Adding new classification YAMLs automatically extends what `/fix` can detect — no plugin changes needed.

## Publishing Rules

To push rules to your Gomboc Community Edition account:

1. Set your Personal Access Token: `export RULE_SERVICE_TOKEN=your-pat-here`
2. Run `/gomboc-community:push-rule` from your rule directory

## Rule Package Structure

Each rule is a self-contained directory:

```
my-rule/
├── my-rule.orl            # Main rule file
├── test.orl               # Test definition
├── workspace/             # Source files with violations
└── workspace_expected/    # Source files after remediation
```

## License

MIT
