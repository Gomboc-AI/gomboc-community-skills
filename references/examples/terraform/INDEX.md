# Terraform ORL Examples Index

Each example is a complete rule package (`*.orl`, `test.orl`, `workspace/`, `workspace_expected/`).
The focus is on **ORL patterns**, not the specific AWS resource or property being enforced.

---

## ensure_aws_db_instance_is_not_publicly_accessible

**Pattern: simple scalar — wrong value or missing (baseline template helpers)**

The starting template for any Terraform rule enforcing a flat boolean/scalar attribute:
- Rule 1 — explicit wrong value: `anAttributeValueEq("attr", "true")`; `replace` path `value`
- Rule 2 — attribute absent: `aMissingAttribute("attr")`; `insert_after` path `body` with `prefix: "\n\n"` and `indent: "  "`

Use this as the canonical starting point before reaching for more complex helpers.

---

## ensure_instance_api_termination_protection_is_enabled

**Pattern: simple scalar — any non-compliant value (using `anAttributeValueNotEq`)**

Identical structure to `ensure_aws_db_instance_is_not_publicly_accessible`, but uses `anAttributeValueNotEq` for Rule 1 instead of `anAttributeValueEq`. Use this when any value other than the target is a violation (e.g., `"true"` is the only valid value regardless of what was written).

Key difference from the baseline: `anAttributeValueEq` targets a specific bad value; `anAttributeValueNotEq` targets everything except the good value.

---

## ensure_aws_instance_block_devices_are_encrypted

**Pattern: attribute inside a named block + `vars` template injection + `skip_finding` on `finding.body`**

Extends the baseline to target an attribute one level deeper inside a named block:
- Uses `aBlock("ebs_block_device", ...)` to scope into a nested block; `insert_after` targets `block_body` (not `body`)
- Rule 3 (CMK injection): `skip_finding: "vars.default?.aws_instance_ebs_block_device_cmk_kms_key_id == nil"` — gates a rule on a user-supplied variable being present; remediation value uses `{{ vars.default.key }}` template interpolation
- `skip_finding: "hasSubString(finding.body, \"snapshot_id\")"` — acceptable scalar-body text check (short, unambiguous string, not structural detection)

Also includes a parallel `ensure_aws_instance_root_block_device_is_encrypted.orl` for `root_block_device` — demonstrates splitting structurally identical rules across two `.orl` files when the block names differ.

---

## ensure_instance_metadata_service_version_1_is_not_enabled_for_aws_instance

**Pattern: all four cases for an attribute inside a block — wrong value, missing, empty block, missing block**

The most complete template-helper coverage for a nested attribute:
- Rule 1 — wrong value in existing block: `aBlock("metadata_options", anAttributeValue("http_tokens", "(#match? @value \"optional\")"))` + `replace`
- Rule 2 — attribute missing in existing block: `aBlock("metadata_options", aMissingAttribute("http_tokens"))` + `insert_after` on `block_body`
- Rule 3 — block exists but is empty: `anEmptyBlock("metadata_options")` + `insert_before` on `block_end` (with `prefix`/`suffix` to place content before the closing brace)
- Rule 4 — block entirely absent: `aMissingBlock("metadata_options")` + `insert_after` on `body` to add the whole block

Also demonstrates using `collect` (`anAttribute("http_endpoint")`) + `skip_finding` with `first(filter(...))` to conditionally skip rules based on a sibling attribute's value.

---

## ensure_rds_database_has_iam_authentication_enabled

**Pattern: `collect` + `skip_finding` with version gating via `semVerCmp`**

Introduces the full `collect` → `skip_finding` idiom for scoping rules to compatible resource variants:
- `collect` gathers `engine` and `engine_version` attribute values for each resource
- `skip_finding` uses `first(filter(flatten(collect(collections, "engine.*")), { #.name == finding.name }))` to retrieve a sibling attribute's value
- `semVerCmp(version, "<", "10.6.5")` gates the rule on semantic version compatibility
- Same 2-rule structure (wrong value + missing) as the baseline, but both gated by the engine/version check

Key idiom: `trim(...?.value ?? "\"\"", "\"")` pattern for safely unwrapping a collected nullable value.

---

## ensure_db_instance_exports_logs_to_cloudwatch

**Pattern: dynamic remediation value computed from `collect` — multi-engine branching with `orl-expr` templates**

The most advanced Terraform example. Shows how to compute the remediation value dynamically at fix time:
- `collect` gathers `engine` and `iam_database_authentication_enabled` for each resource
- `skip_finding` uses full `orl-expr` branching (`if/else` chains, `hasSubString`, `lower`) to decide correctness per engine type
- Remediation `value` uses `{{ ... }}` template blocks with `join()`, `lower()`, `hasSubString()`, and nested `if/else` to produce the correct log list per engine
- Demonstrates that `replace` and `insert_after` remediation values can both use `orl-expr` template expressions, not just static strings
- Two rules: existing attribute (check + replace) and missing attribute (skip aurora/custom + insert)
