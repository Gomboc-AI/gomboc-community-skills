---
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebSearch, WebFetch
description: Create an ORL rule end-to-end — plan, build, add metadata, and optionally push to the Gomboc Rules Service.
---

# Create ORL Rule

You are orchestrating the full ORL rule creation workflow for a community user. Follow these steps in order, with user confirmation between each phase.

## ORL via Docker

ORL is distributed as a Docker image. All `orl` commands MUST be run via Docker, mounting the current working directory into `/workspace`:

```bash
docker run -v "${PWD}:/workspace" gombocai/orl <command> [args...]
```

## Input

The user provides:
- A description of the security/compliance policy to enforce
- The target language: any ORL language ID from `references/orl-supported-languages.md` (confirm with `docker run gombocai/orl language`)
- The target resource type or code construct

## Workflow

### Phase 1: Plan

Invoke the `plan-rule` skill with the user's requirements.

1. Analyze the user's request to identify language, provider, resource, and objective
2. Research the target resource documentation
3. Assess remediability (FULL_REMEDIATION, AUDIT_ONLY, or UNREMEDIATEABLE)
4. Identify test cases and create before/after code samples
5. Write a `plan.md` file with the plan

**Ask the user to review and confirm the plan before continuing.**

If the user wants changes, update the plan accordingly.

### Phase 2: Build

Invoke the `build-rule` skill using the confirmed plan.

1. Create the rule directory structure with workspace files
2. Explore the AST: `docker run -v "${PWD}:/workspace" gombocai/orl walk workspace --language <lang> ./workspace`
3. Write the ORL rule (.orl file)
4. Write the test definition (test.orl)
5. Run tests: `docker run -v "${PWD}:/workspace" gombocai/orl test .`

**If tests fail**, iterate: examine the diff output, adjust the rule or expected files, and re-test. Maximum 5 iterations.

Show the user the test results.

### Phase 3: Add Metadata

Invoke the `add-metadata` skill on the completed rule.

1. Read the rule file
2. Determine provider, resource, and purpose
3. Search classifications for relevant policy mappings
4. Add metadata fields to the rule
5. Validate the YAML is still parseable

Show the user the metadata that was added.

### Phase 4: Push (Optional)

Ask the user: "Would you like to push this rule to the Gomboc Rules Service?"

If yes, invoke the `push-rule` skill:
1. Verify `RULE_SERVICE_TOKEN` is set in the user's environment
2. Run tests one final time: `docker run -v "${PWD}:/workspace" gombocai/orl test .`
3. Push: `docker run -v "${PWD}:/workspace" -e RULE_SERVICE_TOKEN gombocai/orl rules push .`
4. Report success or failure

If no, inform the user the rule is complete and ready for local use or manual publishing.

## Example Usage

```
/gomboc-community:create-rule Ensure all AWS S3 buckets have server-side encryption enabled using Terraform
```

```
/gomboc-community:create-rule Ensure Azure Storage Accounts require HTTPS only using Bicep
```

```
/gomboc-community:create-rule Ensure CloudFormation Elasticsearch domains have encryption at rest
```

```
/gomboc-community:create-rule Ensure Dockerfiles use pinned image digests instead of mutable tags
```

```
/gomboc-community:create-rule Ensure Kubernetes Deployments set runAsNonRoot in securityContext
```

```
/gomboc-community:create-rule Ensure Python requests calls use verify=True for SSL
```
