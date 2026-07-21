# Gomboc ORL Community Skills

A Claude Code plugin for scanning, fixing, and creating ORL (Open Remediation Language) rules across Infrastructure as Code, containers, orchestration, and application code. Supports Terraform, HCL/Terragrunt, CloudFormation (YAML + JSON), Bicep, Dockerfile, Kubernetes, and Python.

**Contributor guide:** see [AGENT_DEV.md](./AGENT_DEV.md) for the `gomboc_community_*` skill architecture (flow / task / cap / know), registration, and maintenance conventions.

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

To push rules, set `GOMBOC_PAT` and map it for `orl` (see `gomboc_community_know_orl_runtime_resolution`):

```bash
docker run -v "${PWD}:/workspace" -e RULE_SERVICE_TOKEN="${GOMBOC_PAT}" gombocai/orl rules push .
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

**Workflow:** `gomboc_community_flow_fix` → diagnose → apply fixes → optionally enrich / release

### `/create-rule` — Create a Rule from Scratch

Define a security or compliance policy and build a complete ORL rule package with tests.

```
/gomboc-community:create-rule Ensure all AWS S3 buckets have server-side encryption enabled using Terraform
/gomboc-community:create-rule Ensure Dockerfiles use pinned image digests instead of mutable tags
/gomboc-community:create-rule Ensure Kubernetes Deployments set runAsNonRoot in securityContext
```

**Workflow:** `gomboc_community_flow_create_rule` → plan → build → review → enrich → optionally release

### `/convert-sentinel` — Convert Sentinel to ORL

Convert a HashiCorp Sentinel policy into one or more tested ORL rules.

**Workflow:** `gomboc_community_flow_convert_sentinel`

### `/verify-mcp` — Verify Hosted Gomboc MCP

Confirm the hosted Gomboc MCP server is configured and working (server ready + `get_channels` smoke call).

```
/gomboc-community:verify-mcp
```

**Skill:** `gomboc_community_know_gomboc_mcp` — setup, prefer-MCP vs Docker/`orl` fallback, soft capability map.

## Skills

Skills use the layered `gomboc_community_*` naming (flow / task / cap / know). See [AGENT_DEV.md](./AGENT_DEV.md).

### Flows

| Skill | Description |
|-------|-------------|
| `gomboc_community_flow_fix` | `/fix` orchestrator — diagnose → apply → optional save |
| `gomboc_community_flow_create_rule` | `/create-rule` orchestrator — plan → build → review → enrich → release |
| `gomboc_community_flow_diagnose` | Classification-driven analyzer and rule-coverage report |
| `gomboc_community_flow_apply_fix` | Apply via existing rule or generate a new one |
| `gomboc_community_flow_build_rule` | Create workspace, write ORL rule, test |
| `gomboc_community_flow_review_rule` | Pre-release compliance fix and report |
| `gomboc_community_flow_convert_sentinel` | Sentinel → ORL conversion pipeline |

### Tasks

| Skill | Description |
|-------|-------------|
| `gomboc_community_task_orl_planner` | Plan requirements, remediability, and test cases |
| `gomboc_community_task_enrich_rule` | Add community metadata for publishing |
| `gomboc_community_task_release_rule` | Validate and push to the Rules Service |
| `gomboc_community_task_resolve_existing_rules` | Local-first → cache → MCP lookup → `orl rules pull` |
| `gomboc_community_task_setup_rule_workspace` | Create package dirs and fixtures |
| `gomboc_community_task_write_orl_rule` | Author `.orl` and `test.orl` |
| `gomboc_community_task_run_orl_test_loop` | Test and iterate until pass |

### Caps

| Skill | Description |
|-------|-------------|
| `gomboc_community_cap_run_orl_test` | `orl test .` via Docker |
| `gomboc_community_cap_orl_remediate` | `orl remediate` (dry-run default) |
| `gomboc_community_cap_orl_walk` | `orl walk` AST explore |
| `gomboc_community_cap_orl_rules_pull` | `orl rules pull` (`--search` / `--channel`) |
| `gomboc_community_cap_orl_rules_push` | `orl rules push` |

### Know

| Skill | Description |
|-------|-------------|
| `gomboc_community_know_gomboc_mcp` | Hosted MCP setup, prefer-MCP vs Docker/`orl`, soft tool map |
| `gomboc_community_know_orl_runtime_resolution` | Docker `gombocai/orl` invocation |
| `gomboc_community_know_language_guidance` | Per-language authoring notes |
| `gomboc_community_know_sentinel_conversion` | Sentinel vs ORL paradigm |
| `gomboc_community_know_release_checklist` | Release-readiness criteria |

## Supported Languages

| Language | ORL Language ID | Use Case |
|----------|----------------|----------|
| Terraform | `terraform` | AWS, Azure, GCP infrastructure |
| HCL | `hcl` | Terragrunt, Packer, Consul, Vault configs |
| CloudFormation YAML | `cloudformation-yaml` | AWS infrastructure (YAML format) |
| CloudFormation JSON | `cloudformation-json` | AWS infrastructure (JSON format) |
| Bicep | `bicep` | Azure infrastructure |
| Dockerfile | `docker` | Container image definitions |
| Kubernetes | `kubernetes` | K8s manifests (Deployments, Pods, Services, etc.) |
| Python | `python` | Application code, AWS CDK, Pulumi, SDK usage |

## Classification-Driven Analysis

The `/fix` command uses the ORL classification policy corpus (`/orl-rules/final/classifications/policies/`) as its knowledge base. Each classification YAML defines:

- What security or compliance policy to enforce
- Which languages and resource types it applies to
- Impact and risk scores for prioritization
- Compliance framework mappings (CIS, NIST CSF, PCI-DSS, AWS Well-Architected, etc.)

Adding new classification YAMLs automatically extends what `/fix` can detect — no plugin changes needed.

## Publishing Rules

To push rules to your Gomboc Community Edition account:

1. Set your Personal Access Token: `export GOMBOC_PAT=your-pat-here`
2. Run `/gomboc-community:create-rule` (or release after `/fix` save) so **`gomboc_community_task_release_rule`** runs

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
