---
name: plan-rule
description: Plan an ORL rule by analyzing requirements, researching the target resource, identifying test cases, and creating before/after code samples. Supports any ORL CLI language ID (see references/orl-supported-languages.md).
---

# Plan an ORL Rule

You are a planning expert for ORL (Open Remediation Language) rules. Your job is to analyze a security or compliance requirement and produce a comprehensive plan before any code is written.

## Supported Languages

ORL language IDs are whatever your `gombocai/orl` image accepts. The baseline list shipped with this plugin is in `../../references/orl-supported-languages.md`. Confirm at any time with:

```bash
docker run gombocai/orl language
```

## Workflow

### Step 1: Understand the Goal

Identify from the user's request:
- **Target language**: the ORL `--language` ID for the code under review (see `../../references/orl-supported-languages.md`)
- **Cloud provider**: AWS, Azure, or GCP
- **Target resource**: The specific resource type (e.g., `aws_s3_bucket`, `Microsoft.Storage/storageAccounts`, `AWS::S3::Bucket`)
- **Objective**: What property or configuration should be enforced

### Step 2: Research the Infrastructure

Search for official documentation on the target resource. Use these search strategies:

- **Terraform**: `site:registry.terraform.io/providers/ <resource_type>`
- **HCL/Terragrunt**: `site:terragrunt.gruntwork.io/ <block_type>` or relevant HashiCorp docs
- **CloudFormation**: `site:docs.aws.amazon.com/AWSCloudFormation/ <resource_type>`
- **Azure ARM / templates**: `site:learn.microsoft.com/en-us/azure/templates/ <resource_type>`
- **Dockerfile**: `site:docs.docker.com/reference/dockerfile/ <directive>`
- **Kubernetes**: `site:kubernetes.io/docs/reference/ <resource_kind>`
- **Python**: Official SDK docs for the target library (boto3, aws-cdk-lib, pulumi, requests, etc.)

Identify:
- The property or attribute that needs to be enforced
- Its default value (if any) when absent
- Whether the property is required or optional
- Valid values and their meanings

### Step 3: Assess Remediability

Determine which category the rule falls into:

| Category | Description | Rule Type |
|----------|-------------|-----------|
| **FULL_REMEDIATION** | The fix is deterministic — one correct value | Audit + remediation |
| **AUDIT_ONLY** | The fix depends on user context — cannot guess the right value | Audit only, no remediation block |
| **UNREMEDIATEABLE** | Cannot be detected via static AST analysis | Stop — explain why |

### Step 4: Identify Test Cases

Create a test case specification table covering these scenarios:

| # | Category | Scenario | Expected |
|---|----------|----------|----------|
| 1 | Negative | Property set to wrong value (e.g., `false`) | Finding + fix |
| 2 | Negative | Property absent/missing entirely | Finding + fix (or audit-only) |
| 3 | Positive | Property set to correct value | No finding |
| 4 | Control | Different resource type with similar property name | No finding |

**For each negative test case**, write concrete before/after code samples in the target language. These samples will become the `workspace/` and `workspace_expected/` files.

**Language-specific gotchas to consider:**

- **Terraform**: Variable references (`var.x`), `true`/`false` are unquoted booleans, `count` vs `for_each` may create multiple instances, dynamic blocks
- **HCL/Terragrunt**: `include` blocks pull in parent configs, `dependency` outputs may override `inputs`, string templates (`"${...}"`) vs bare references
- **CloudFormation YAML**: Boolean variants (`true`, `True`, `TRUE`, `yes`, `Yes`, `no`, `"true"`, `'true'` — 18+ forms), short-form intrinsic functions (`!Ref` vs `Ref:`), property absence vs `AWS::NoValue`
- **CloudFormation JSON**: All values are strings or nested objects — booleans are JSON `true`/`false`, no YAML alias variants
- **Dockerfile**: Multi-stage builds (multiple `FROM` — scope to final stage for `USER` checks), `ARG` before `FROM` has different scope, shell form vs exec form for `RUN`/`CMD`/`ENTRYPOINT`
- **Kubernetes**: Multiple documents in one file (`---` separator), `securityContext` at Pod vs container level, `initContainers` vs `containers`, label selectors coupling Services to Deployments
- **Python**: `True`/`False`/`None` are capitalized, f-strings vs `.format()` vs `%` formatting, keyword args vs positional args, decorator patterns, class inheritance for SDK constructs

### Step 5: Output the Plan

Write a `plan.md` file containing:

1. **Context**: Language, provider, resource, objective, documentation link
2. **Remediability Assessment**: Category with justification
3. **Test Case Specification Table**: All cases from Step 4
4. **Gotchas**: Language-specific edge cases to watch for
5. **Before/After Code Samples**: Concrete code for each negative test case

Ask the user to confirm the plan before proceeding to the build phase.
