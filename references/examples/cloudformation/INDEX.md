# CloudFormation ORL Examples Index

Each example is a complete rule package (`*.orl`, `test.orl`, `workspace/`, `workspace_expected/`).
The focus is on **ORL patterns**, not the specific AWS resource or property being enforced.

---

## ebs-encryption-enabled

**Pattern: simple scalar — missing or falsy value**

The baseline pattern for a flat boolean property on a CloudFormation resource:
- Rule 1 — property absent: `[...]*` with `(#not-eq? @key "Encrypted")` to detect absence; `insert_after` on `@properties`
- Rule 2 — property falsy: match `@value` with explicit false-y regex; `replace` the value node

No `collect` needed. Use this as the starting template for any rule that sets a single boolean property.

---

## ensure_elasticsearch_domain_encryption_at_rest

**Pattern: nested boolean — missing sub-block or falsy leaf, no collect**

Like `ebs-encryption-enabled` but the target property is one level deeper (`EncryptionAtRestOptions.Enabled`):
- Rule 1 — outer block absent: `[...]*` + `(#not-eq? @key "EncryptionAtRestOptions")`; `insert_after` the whole block
- Rule 2 — inner key absent: `[...]*` + `(#not-eq? @key "Enabled")` inside the sub-block; `insert_after` inside the sub-block with deeper indent
- Rule 3 — inner value falsy: explicit `#match?` on `@enabled_value`; `replace` the value node

Shows how to navigate into a nested sub-mapping without `collect`.

---

## encryption_at-rest_with_provider_managed_key_for_aws--amazonmq--broker

**Pattern: nested boolean with alternate resource layout**

Variation on the nested boolean pattern for a different resource and property path.
Useful for cross-checking indentation and `insert_after` path choices when the property nesting differs.

---

## elasticsearch-node-to-node-encryption

**Pattern: nested boolean — full edge-case coverage with collect**

Extends `ensure_elasticsearch_domain_encryption_at_rest` to handle every YAML edge case:
- Uses `collect` (`es_domain_resources`, `has_n2n_key`) + `skip_finding` with `!any(...)` negation to gate rules
- Rule 1 — outer block absent: same `[...]*` absent-key pattern as above
- Rule 2 — inner key absent: `[...]*` absent-key inside sub-block; `insert_after` inside sub-block
- Rule 3 — inner value falsy: `#not-match?` with full truthy regex (all case variants); `replace` value
- Rule 4 — block is empty `{}` flow mapping: `(flow_mapping)` node detection; `replace` the entire `@n2n_empty_pair` key-value pair
- Rule 5 — block is null (bare `Key:` with no value): `#match? @n2n_null_pair "^NodeToNodeEncryptionOptions:[ \t]*$"` on the pair node text; `replace` entire pair

Key techniques: `(flow_mapping)` matching, `replace` on a full pair node, node-text regex for null YAML values.

---

## alb-listener-https

**Pattern: property in a resource with list-valued sibling — skip if already-compliant list item exists**

Demonstrates navigating `block_sequence` / `block_sequence_item` nodes and detecting CloudFormation intrinsic functions:
- `collect` (`redirect_https_action`) — walks deep into `DefaultActions[*].RedirectConfig.Protocol` to find resources that already redirect to HTTPS; uses `(#match? @_action_type_value "^[\"']?redirect[\"']?$")` for quoted/unquoted string matching
- `collect` (`dynamic_default_actions`) — detects resources whose `DefaultActions` is a dynamic value (`!Ref`/`!If` tag OR a block mapping); uses `[(flow_node (tag)) (block_node (block_mapping))] @value` alternation
- Rule 1 — `Protocol` is `HTTP`: `(#match? @protocol_value "^[\"']?HTTP[\"']?$")`; `replace` with `HTTPS`; skipped if redirect-to-HTTPS action or dynamic actions present
- Rule 2 — `Protocol` absent: `[...]*` + `(#not-eq? @key "Protocol")`; `insert_after` properties; skipped if dynamic actions present

Key techniques: `block_sequence` → `block_sequence_item` traversal, `(flow_node (tag))` for intrinsic function detection, multi-collect OR logic in `skip_finding`.

---

## kms-key-rotation-enabled

**Pattern: conditional rule scope — exclude a resource subtype via collect**

Demonstrates using `collect` to identify which resources a rule should *not* apply to:
- `collect` (`symmetric_keyspec_resources`) — finds resources with `KeySpec: SYMMETRIC_DEFAULT`
- `collect` (`has_keyspec_resources`) — finds resources that have *any* `KeySpec` value
- Rule 1 — `EnableKeyRotation` absent, no explicit `KeySpec`: two simultaneous `(#not-eq?)` constraints (`#not-eq? @key "EnableKeyRotation"` AND `#not-eq? @key "KeySpec"`) in the same `[...]*` group; `insert_after` properties
- Rule 2 — `EnableKeyRotation` absent, explicit `SYMMETRIC_DEFAULT`: same absent-key pattern but gated by `skip_finding: !any(symmetric_keyspec_resources...)`
- Rule 3 — `EnableKeyRotation` falsy, no explicit `KeySpec`: `(#not-match? @rotation_value "(?i)^[\"']?(true|yes|on|1)[\"']?$")` case-insensitive; also `(#not-match? @rotation_value "^!")` to skip intrinsic functions by text
- Rule 4 — `EnableKeyRotation` falsy, explicit `SYMMETRIC_DEFAULT`: same as Rule 3 with subtype gate

Key techniques: multi-`#not-eq?` in `[...]*`, `(?i)` case-insensitive regex, `#not-match? @value "^!"` to skip intrinsic functions without structural `(flow_node (tag))` detection, four-rule split by (absent vs falsy) × (KeySpec present vs absent).
