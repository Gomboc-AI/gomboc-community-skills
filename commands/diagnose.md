---
allowed-tools: Bash, Read, Glob, Grep
description: Scan source code for security anti-patterns and compliance gaps; report findings and existing-rule coverage.
---

# Diagnose Source Code

Load and execute **`gomboc_community_flow_diagnose`**.

## Example Usage

```
/gomboc-community:diagnose main.tf
/gomboc-community:diagnose ./infrastructure/
/gomboc-community:diagnose k8s/ — least privilege
/gomboc-community:diagnose . — CIS compliance check
```
