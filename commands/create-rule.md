---
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebSearch, WebFetch
description: Create an ORL rule end-to-end — plan, build, review, enrich, and optionally push to the Gomboc Rules Service.
---

# Create ORL Rule

Load and execute **`gomboc_community_flow_create_rule`**. That flow is canonical for orchestration.

## Summary

1. **`gomboc_community_task_orl_planner`** — confirm plan with the user.
2. **`gomboc_community_flow_build_rule`** — package + tests.
3. **`gomboc_community_flow_review_rule`** — release-readiness fixes.
4. **`gomboc_community_task_enrich_rule`** — community metadata.
5. Optional **`gomboc_community_task_release_rule`** — Rules Service push.

## Example Usage

```
/gomboc-community:create-rule Ensure all AWS S3 buckets have server-side encryption enabled using Terraform
/gomboc-community:create-rule Ensure Dockerfiles use pinned image digests instead of mutable tags
/gomboc-community:create-rule Ensure Kubernetes Deployments set runAsNonRoot in securityContext
```
