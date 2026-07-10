---
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebSearch, WebFetch
description: Convert a HashiCorp Sentinel policy (from a URL or file path) into one or more ORL rules. Analyzes the policy intent, builds tested rule packages, and optionally pushes them to your Gomboc account.
---

# Convert Sentinel Policy to ORL

Load and execute **`gomboc_community_flow_convert_sentinel`**. That flow is canonical for orchestration.

## Summary

1. Retrieve and analyze the Sentinel policy (URL or path).
2. Assess conversion strategy using **`gomboc_community_know_sentinel_conversion`**.
3. Build and test ORL rule package(s) via shared setup / write / test-loop tasks.
4. Enrich metadata; optionally **`gomboc_community_task_release_rule`**.

## Input

- A **URL** to a Sentinel policy file OR a **file path** to a local `.sentinel` file
- Optionally: example Terraform code or Sentinel mock data
