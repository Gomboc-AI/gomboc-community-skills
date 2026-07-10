---
name: gomboc_community_flow_diagnose
description: >-
  Use when scanning code for security/compliance issues — detect language, load policies,
  walk AST, report findings and rule coverage. Depends on:
  gomboc_community_know_orl_runtime_resolution, gomboc_community_know_language_guidance,
  gomboc_community_task_resolve_existing_rules, gomboc_community_cap_orl_walk.
---

# Flow: Diagnose

Scan source files, match ORL classification policies, and report prioritized findings with rule coverage. Prefer dependencies over inlined Docker/`orl` commands.

## Process

### Step 1 — Detect language & scope

1. Read target files / list the target directory.
2. Group by ORL language using **`gomboc_community_know_language_guidance`** (extensions + disambiguation).
3. Skip out-of-scope files.

### Step 2 — Load matching classifications

1. Read classification references under `references/` (e.g. `references/examples/classifications.txt`).
2. Filter by `gomboc-ai/iac` languages intersecting detected languages.
3. Optionally filter by user concern keywords and/or compliance framework (`gomboc-ai/framework`).

### Step 3 — Identify resources & structures

For each language, explore with **`gomboc_community_cap_orl_walk`**. Extract resource types / constructs relevant to that language (see know guidance).

### Step 4 — Match policies to code

For each applicable classification:

1. Match `gomboc-ai/resources` (or resource-agnostic policies) against Step 3.
2. Walk the AST for the anti-pattern described in the classification (see [Anti-pattern reference](#anti-pattern-detection-reference)).
3. Resolve coverage with **`gomboc_community_task_resolve_existing_rules`** — do not inline pull/search strategies here.
4. Record the finding with classification + resolve status (`existing` / `partial` / `none`).

### Step 5 — Score & report

For each finding, take severity/risk/frameworks from the classification. Sort HIGH first, then by file location. Present a numbered table and ask which issues to fix.

```
Findings for <path> (<languages>)

  #  Severity  File:Line     Policy                         Status
  1  HIGH      main.tf:12    encryption/...                 existing
  2  MEDIUM    Dockerfile:1  supply_chain_protection/...    none

Fix which issues? [1,2,.../all]
```

## Anti-pattern detection reference

#### Infrastructure as Code (Terraform, CloudFormation, Bicep)

| Policy Domain | What to Check |
|--------------|--------------|
| `encryption/encryption_at_rest` | Missing encryption blocks, encryption false, missing KMS refs |
| `encryption/encryption_in_transit` | TLS disabled, HTTP, weak TLS |
| `secure_networking/prevent_public_access` | Public access, `0.0.0.0/0`, public subnets |
| `authentication` | Missing IAM auth, anonymous access |
| `disaster_recovery/automatic_backups` | Backup disabled / retention 0 |
| `accidental_deletion_protection` | Missing deletion protection |
| `surface_area/auditing_and_monitoring` | Logging/metrics disabled |
| `inventory/resource_tags` | Missing required tags |
| `cost_management` | Oversized / missing autoscaling |

#### HCL / Terragrunt

| Policy Domain | What to Check |
|--------------|--------------|
| `encryption/encryption_in_transit` | Unencrypted remote_state / backend |
| `secure_management/best_practice` | Missing prevent_destroy / validation |
| `sensitive_information_handling` | Secrets in inputs/locals |
| `authentication` | Static credentials in provider config |

#### Dockerfile

| Policy Domain | What to Check |
|--------------|--------------|
| `supply_chain_protection/immutable_docker_image_tags` | Mutable tags vs digests |
| `secure_management/least_privilege` | Missing / root `USER` |
| `sensitive_information_handling` | Secrets in ENV/ARG/RUN |
| `surface_area/auditing_and_monitoring` | Missing HEALTHCHECK |

#### Kubernetes

| Policy Domain | What to Check |
|--------------|--------------|
| `secure_management/least_privilege` | Privileged / missing runAsNonRoot |
| `secure_networking/prevent_public_access` | Public LoadBalancer / missing NetworkPolicy |
| `surface_area/capacity_planning_and_resilience` | Missing resource limits/requests |
| `sensitive_information_handling` | Secrets in env (not secretKeyRef) |
| `supply_chain_protection/immutable_docker_image_tags` | Mutable image tags |

#### Python

| Policy Domain | What to Check |
|--------------|--------------|
| `prevent_code_injection` | eval/exec, shell=True, unsafe SQL/templates |
| `sensitive_information_handling` | Hardcoded secrets |
| `encryption/encryption_in_transit` | verify=False / insecure TLS |
| `vulnerability_management` | Insecure APIs (md5, pickle, unsafe yaml) |

## Constraints

- Rule discovery/pull belongs in **`gomboc_community_task_resolve_existing_rules`** / **`gomboc_community_cap_orl_rules_pull`**.
- Runtime via **`gomboc_community_know_orl_runtime_resolution`**.
