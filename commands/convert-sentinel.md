---
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebSearch, WebFetch
description: Convert a HashiCorp Sentinel policy (from a URL or file path) into one or more ORL rules. Analyzes the policy intent, builds tested rule packages, and optionally pushes them to your Gomboc account.
---

# Convert Sentinel Policy to ORL

You are orchestrating the conversion of a HashiCorp Sentinel policy into ORL rules for a community user. Follow the phases below with user confirmation between each.

## ORL via Docker

ORL is distributed as a Docker image. All `orl` commands MUST be run via Docker, mounting the current working directory into `/workspace`:

```bash
docker run -v "${PWD}:/workspace" gombocai/orl <command> [args...]
```

## Input

The user provides:
- A **URL** to a Sentinel policy file (e.g., a GitHub raw link) OR a **file path** to a local `.sentinel` file
- Optionally: example Terraform code the policy targets, or Sentinel mock data files

## Workflow

### Phase 1: Retrieve and Analyze

1. Fetch or read the Sentinel policy
2. Identify the target Terraform resources, attributes, and enforcement conditions
3. Determine the conversion strategy for each condition:
   - **FIX** — deterministic remediation possible
   - **AUDIT-ONLY** — violation detection only (no safe auto-fix)
4. Present the conversion plan to the user:

```
Sentinel policy analysis:

  Policy: <policy-name>
  Severity: <advisory|soft-mandatory|hard-mandatory>
  Target resources: <resource types>

  Conversion plan:
  1. [FIX]        <description of first sub-rule>
  2. [FIX]        <description of second sub-rule>
  3. [AUDIT-ONLY] <description of third sub-rule>

  Limitations:
  - <any Sentinel checks that cannot be converted, with explanation>

  Proceed? [Y/n]
```

**Ask the user to review and confirm the plan before continuing.**

If the user wants changes, update the plan accordingly.

### Phase 2: Build Rules

Invoke the `convert-sentinel` skill using the confirmed plan.

For each sub-rule in the plan:

1. Create the rule directory structure with workspace files
   - Map Sentinel mock data or policy conditions to test `.tf` files
   - Include: valid (compliant), missing attribute, wrong value, invalid reference cases
   - For audit-only rules: workspace and workspace_expected are identical
2. Explore the AST: `docker run -v "${PWD}:/workspace" gombocai/orl walk workspace --language terraform ./workspace`
3. Write the ORL rule using Terraform template helpers
4. Write the test definition (`test.orl`)
5. Run tests: `docker run -v "${PWD}:/workspace" gombocai/orl test .`

**If tests fail**, iterate: examine the diff output, adjust the rule or expected files, and re-test. Maximum 5 iterations.

Show the user the test results.

### Phase 3: Add Metadata

Invoke the `add-metadata` skill on each completed rule.

1. Set `gomboc-ai/source: "sentinel"` annotation to record provenance
2. Set `gomboc-ai/sentinel-policy: "<policy-name>"` to link back to the original
3. Search `../../references/classifications.txt` for relevant policy classifications
4. Add standard metadata fields (display_name, description, provider, resource, etc.)

Show the user the metadata that was added.

### Phase 4: Share (Optional)

Present the results and ask the user:

```
Conversion complete! All tests passing.

  Original Sentinel policy: <policy-name>
  Rules created: <N>

  Summary:
    - <rule-1-name> (fix) — <brief description>
    - <rule-2-name> (fix) — <brief description>
    - <rule-3-name> (audit-only) — <brief description>

Would you like to share this rule to your Gomboc account?
  1. Yes — push to my account (requires RULE_SERVICE_TOKEN)
  2. No — keep locally only
```

**If yes:**
1. Verify `RULE_SERVICE_TOKEN` is set in the environment
2. Run tests one final time
3. Push each rule: `docker run -v "${PWD}:/workspace" -e "${RULE_SERVICE_TOKEN}" gombocai/orl rules push .`
4. Report success with the published rule name(s)

**If no:**
1. Report the local path to the rule package(s)
2. Inform the user they can push later with `/gomboc-community:push-rule`

## Example Usage

```
/gomboc-community:convert-sentinel https://raw.githubusercontent.com/hashicorp/terraform-sentinel-policies/main/aws/restrict-ec2-instance-type.sentinel
```

```
/gomboc-community:convert-sentinel ./policies/require-most-recent-ami-version.sentinel
```

```
/gomboc-community:convert-sentinel https://github.com/hashicorp/terraform-sentinel-policies/blob/main/aws/restrict-s3-bucket-policies.sentinel
```
