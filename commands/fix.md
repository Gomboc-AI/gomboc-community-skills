---
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebSearch, WebFetch
description: Scan source code for security anti-patterns and compliance gaps, then fix them — using existing ORL rules or generating new ones on the fly. Optionally save fixes as reusable rules.
---

# Fix Source Code

Load and execute **`gomboc_community_flow_fix`**. That flow is canonical for orchestration.

## Summary

1. **`gomboc_community_flow_diagnose`** — scan and report findings; ask which to fix.
2. **`gomboc_community_flow_apply_fix`** — existing rule or generate; dry-run; confirm; apply.
3. Optional **`gomboc_community_task_enrich_rule`** / **`gomboc_community_task_release_rule`** for new rules.

Resolve ORL via **`gomboc_community_know_orl_runtime_resolution`**. Prefer caps for CLI.

## Example Usage

```
/gomboc-community:fix main.tf — check encryption
/gomboc-community:fix ./infrastructure/ — security review
/gomboc-community:fix Dockerfile
/gomboc-community:fix k8s/ — least privilege
/gomboc-community:fix src/api/ — prevent code injection
/gomboc-community:fix . — CIS compliance check
```
