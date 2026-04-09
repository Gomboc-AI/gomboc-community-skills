# Plan: Community Skills — Claude Code Plugin for ORL Rule Creation

## Context

The existing `/app/skills/` directory contains 64+ skills with a complex multi-stage ORL pipeline designed for enterprise workflows with formal handoffs, structured data blocks, and workflow orchestration scripts. Community users need a streamlined experience: plan a rule, build it, add basic metadata, push it — all with minimal ceremony. This plan creates a self-contained Claude Code plugin under `/app/community-skills/` targeting only Terraform, CloudFormation YAML, and Bicep, publishable to the Anthropic Marketplace.

---

## Directory Structure

```
/app/community-skills/
├── .claude-plugin/
│   └── plugin.json                    # Plugin manifest
├── marketplace.json                   # Marketplace definition
├── DESIGN.md                          # This file
├── README.md                          # Installation & usage guide
├── LICENSE                            # MIT license
├── skills/
│   ├── plan-rule/
│   │   └── SKILL.md                   # Merged planner + test-planner
│   ├── build-rule/
│   │   └── SKILL.md                   # Merged expert + fixer + 3 lang experts
│   ├── add-metadata/
│   │   └── SKILL.md                   # Simplified metadata enricher
│   └── push-rule/
│       └── SKILL.md                   # orl rules push wrapper
├── commands/
│   └── create-rule.md                 # Orchestration slash command
├── references/                        # Copied from /app/skills/orl-expert/references/
│   ├── orl-docs.md
│   ├── grammar.md
│   ├── expr-lang.md
│   ├── ast-general.md
│   ├── hcl-ast.md                     # Terraform AST helpers
│   ├── yaml-ast.md                    # CloudFormation YAML AST
│   ├── bicep-ast.md                   # Extracted from language-bicep-expert
│   ├── classifications.txt            # Filtered to gomboc-ai/policy/* only
│   ├── schema/
│   │   ├── rule.json
│   │   ├── ruleset.json
│   │   └── test.json
│   └── examples/
│       ├── terraform/                 # Copied from orl-expert examples
│       ├── cloudformation/            # Copied from orl-expert examples
│       └── bicep/                     # New examples created for this plugin
└── assets/
    └── templates/
        ├── base_ruleset.orl
        ├── terraform_ruleset.orl
        └── test.orl
```

---

## Skills Design

### 1. `plan-rule` — Plan an ORL Rule
**Merges:** `orl-planner` + `orl-test-planner` into one skill

**Keeps:**
- Goal analysis (language, provider, resource, objective)
- Web research for target resource documentation
- Remediability assessment (simplified: FULL_REMEDIATION, AUDIT_ONLY, or UNREMEDIATEABLE)
- Test case identification (negative/positive/missing attribute/anti-gamification)
- Concrete before/after code samples for each test case

**Removes:**
- PLAN_DATA_START/END structured output blocks
- TEST_COVERAGE_START/END structured output blocks
- JSON test case file generation (golden-test-cases/)
- Self-assessment blocks
- Language expert mapping table (hardcoded 3 languages instead)
- Formal handoff to separate test-planner skill

**Output:** A single `plan.md` with Context, Test Cases Table, Gotchas, and before/after code samples.

### 2. `build-rule` — Build an ORL Rule
**Merges:** `orl-expert` + `orl-fixer` + language experts for Terraform, CloudFormation YAML, and Bicep

**Keeps:**
- Core rule development process (create workspace/expected, write rule, test with `docker run -v "${PWD}:/workspace" gombocai/orl test .`, debug with `docker run ... gombocai/orl walk`)
- All 11 critical best practices from orl-expert
- Template helpers documentation (aResource, anAttribute, aMissingAttribute)
- ORL syntax refresher from orl-fixer
- Pre-completion checklist

**Embeds directly (not as separate skills):**
- Terraform mechanics: variable refs, booleans, dynamic blocks, count vs for_each, quoted vs unquoted
- CloudFormation YAML mechanics: intrinsic function forms, boolean variants (18+), scalar styles, lists
- Bicep mechanics: parameter refs, decorators, ternary, for loops, parent/child resources, API versions

### 3. `add-metadata` — Add Basic Metadata
**Simplifies:** `orl-metadata-enricher` from 20+ fields to ~8

**Required fields only:**
```yaml
metadata:
  name: <rule-name>
  display_name: <human-readable, max 10 words>
  description: |
    <what the rule does, markdown>
  classifications:
    - <at least one gomboc-ai/policy/* classification>
  annotations:
    contributed-by: <user name or handle>
    gomboc-ai/provider: <AWS|Azure>
    gomboc-ai/resource: <resource type>
    gomboc-ai/visibility: public
    gomboc-ai/public-rule-bodies: "true"
    gomboc-ai/description-plain: <one-line plaintext>
```

### 4. `push-rule` — Push Rule to Gomboc Community Edition
**Process:**
1. Verify rule package structure (has .orl, test.orl, workspace/, workspace_expected/)
2. Run `docker run -v "${PWD}:/workspace" gombocai/orl test .` to confirm all tests pass
3. Execute `docker run -v "${PWD}:/workspace" -e "${RULE_SERVICE_TOKEN}" gombocai/orl rules push .`
4. Report success/failure

**Auth:** User sets `${RULE_SERVICE_TOKEN}` env var with their Gomboc PAT. Passed to Docker via `-e "${RULE_SERVICE_TOKEN}"`.

### 5. `/create-rule` Slash Command
**Orchestrates** the full workflow with user confirmation gates:
1. Invoke `plan-rule` → ask user to confirm plan
2. Invoke `build-rule` → run tests via Docker → iterate if tests fail
3. Invoke `add-metadata` → show metadata to user
4. Ask if user wants to push → invoke `push-rule` if yes

---

## Plugin & Marketplace Manifests

Skills are namespaced as `/gomboc-orl-community:<skill-name>` when installed via the marketplace.

Users install with:
```bash
claude plugin marketplace add Gomboc-AI/gomboc-community-skills
claude plugin install gomboc-orl-community@gomboc-community-marketplace
```

## ORL via Docker

ORL is distributed as a Docker image (`gombocai/orl` on [Docker Hub](https://hub.docker.com/r/gombocai/orl)). All ORL commands run via Docker with the working directory mounted at `/workspace`:

```bash
docker run -v "${PWD}:/workspace" gombocai/orl <command> [args...]
```

Environment variables (e.g., `${RULE_SERVICE_TOKEN}`) are passed with `-e`:

```bash
docker run -v "${PWD}:/workspace" -e "${RULE_SERVICE_TOKEN}" gombocai/orl rules push .
```

---

## Key Design Decisions

| Decision | Choice | Trade-off |
|----------|--------|-----------|
| Copy vs symlink references | Copy | Files may drift from source, but plugin is self-contained for marketplace distribution |
| Embed vs separate language skills | Embed in build-rule | build-rule SKILL.md is larger (~300 lines), but avoids skill-to-skill overhead |
| Drop reviewer skill | Yes | Community rules may have lower quality, but tests via Docker are still required before push |
| Minimal metadata | 8 fields vs 20+ | Rules have less annotation, but covers essentials for discovery |
| Bicep insert pattern | Use `replace` with `{{ $.props_body \| replace("{", "", 1) }}` | Different from Terraform's `insert_after` on body, but works correctly with Bicep's tree-sitter grammar |
