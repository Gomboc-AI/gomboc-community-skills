---
name: gomboc_community_know_language_guidance
description: >-
  Use when you need language-specific ORL authoring gotchas for Terraform, HCL,
  CloudFormation, Bicep, Dockerfile, Kubernetes, or Python. No side effects. Depends on:
  gomboc_community_know_orl_runtime_resolution.
---

# Know: Language Guidance

Load this when writing or reviewing ORL rules. Prefer `references/` in this repo for AST patterns and grammar details.

## Supported languages

| Language | ORL ID | Notes |
|----------|--------|-------|
| Terraform | `terraform` | Booleans unquoted; `count`/`for_each`; dynamic blocks; `var.` refs |
| HCL / Terragrunt | `hcl` | `include`, `dependency`, `inputs`; string templates |
| CloudFormation YAML | `cloudformation-yaml` | Many boolean spellings; `!Ref` vs `Ref:`; `AWS::NoValue` |
| CloudFormation JSON | `cloudformation-json` | JSON booleans; no YAML aliases |
| Bicep | `bicep` | Ternaries; `existing`; single-quoted strings |
| Dockerfile | `docker` | Multi-stage `FROM`; shell vs exec form |
| Kubernetes | `kubernetes` | Multi-doc YAML; Pod vs container `securityContext` |
| Python | `python` | `True`/`False`/`None`; kwargs; CDK/Pulumi constructs |

## Authoring tips

- Explore AST with **`gomboc_community_cap_orl_walk`** before writing queries.
- Keep remediation values deterministic for `FULL_REMEDIATION`; use `AUDIT_ONLY` when the correct value is user-specific.
- See also `references/` and the language sections historically maintained in the build-rule flow for deeper examples.
