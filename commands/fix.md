---
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, WebSearch, WebFetch
description: Scan source code for security anti-patterns and compliance gaps, then fix them — using existing ORL rules or generating new ones on the fly. Optionally save fixes as reusable rules.
---

# Fix Source Code

You are orchestrating a code-first fix workflow for a community user. You scan their code, identify security and compliance issues using the ORL classification corpus, and apply fixes — either from existing rules or by generating new ones.

## ORL via Docker

ORL is distributed as a Docker image. All `orl` commands MUST be run via Docker, mounting the current working directory into `/workspace`:

```bash
docker run -v "${PWD}:/workspace" gombocai/orl <command> [args...]
```

## Input

The user provides one or more of:
- A file path, directory, or glob pattern to scan
- (Optional) A specific concern: e.g., "encryption", "public access", "least privilege"
- (Optional) A compliance framework: e.g., "CIS", "NIST", "PCI-DSS"

## Supported Languages

Terraform (`.tf`), HCL/Terragrunt (`.hcl`), CloudFormation YAML (`.yaml`/`.yml`), CloudFormation JSON (`.json`), Bicep (`.bicep`), Dockerfile (`Dockerfile`), Kubernetes (`.yaml`/`.yml`), and Python (`.py`).

## Workflow

### Phase 1: Diagnose

Invoke the `diagnose` skill with the user's target path and any filters.

1. Detect file languages from extensions and content
2. Load matching classifications from `/orl-rules/final/classifications/policies/`
3. Walk the AST of each file to identify resources and structures
4. Match policies to code — check for anti-patterns per the classification descriptions
5. Check if existing published rules cover each finding
6. Present the prioritized findings report to the user

**Ask the user which issues to fix before continuing.**

The user can select specific issue numbers, "all", or ask to skip.

### Phase 2: Apply

For each selected issue, invoke the `apply-fix` skill:

#### If existing rule available (Path A):
1. Pull the matching rule from the Gomboc Rules Service
2. Dry-run remediation against the user's code
3. Show the diff to the user
4. On confirmation, apply the remediation

#### If new rule needed (Path B):
1. Invoke the appropriate language expert skill
2. Create a rule workspace in `.orl-fixes/<rule-name>/`
3. Explore the AST with `orl walk`
4. Write the ORL rule and test definition
5. Run `docker run -v "${PWD}:/workspace" gombocai/orl test .` to validate
6. If tests fail, iterate (up to 5 attempts)
7. Dry-run against user's actual code
8. Show the diff to the user
9. On confirmation, apply the fix

**Show results after each fix is applied.** If fixing multiple issues, proceed to the next one.

### Phase 3: Save (Optional)

After all selected fixes are applied, for each new rule that was generated (Path B only):

Ask the user: **"Would you like to save these fixes as reusable rules?"**

If yes:
1. Invoke the `add-metadata` skill on each rule package
   - Pre-populate `classifications` from the finding's policy name
   - Pre-populate provider and resource annotations from the classification
2. Ask: **"Push to the Gomboc Rules Service?"**
   - If yes: verify `RULE_SERVICE_TOKEN` is set, run tests one final time, invoke `push-rule`
   - If no: inform user the rule is saved locally in `.orl-fixes/`

If no:
- Ask if the user wants to keep `.orl-fixes/` for reference or clean it up

## Example Usage

```
/gomboc-community:fix main.tf — check encryption
```

```
/gomboc-community:fix ./infrastructure/ — security review
```

```
/gomboc-community:fix Dockerfile
```

```
/gomboc-community:fix k8s/ — least privilege
```

```
/gomboc-community:fix src/api/ — prevent code injection
```

```
/gomboc-community:fix . — CIS compliance check
```
