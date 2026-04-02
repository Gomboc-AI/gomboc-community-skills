---
name: add-metadata
description: Add basic metadata to an ORL rule including name, description, display name, classifications, and provider/resource annotations. Simplified from the full enterprise enrichment process.
---

# Add Metadata to an ORL Rule

You add essential metadata to completed ORL rules so they can be discovered and understood when published to the Gomboc Rules Service.

## Required Metadata Fields

Every rule must have these fields in the `metadata:` section:

```yaml
metadata:
  name: gomboc-ai/<rule-name>
  display_name: <Human Readable Title, max 10 words>
  description: |
    ## Description

    <What the rule does and why, in markdown>
  classifications:
    - gomboc-ai/policy/<category>/<subcategory>
  annotations:
    contributed-by: <user name or handle>
    gomboc-ai/provider: <AWS|Azure|GCP>
    gomboc-ai/resource: <resource type>
    gomboc-ai/visibility: public
    gomboc-ai/public-rule-bodies: "true"
    gomboc-ai/description-plain: "<one-line plaintext description>"
```

## Field Guidelines

### `name`
- Format: `gomboc-ai/<descriptive-snake-case-name>`
- Example: `gomboc-ai/ensure_s3_bucket_encryption_enabled`

### `display_name`
- Maximum 10 words
- Format: `<action> <resource> <goal>`
- Examples:
  - "Ensure S3 Bucket Encryption at Rest"
  - "Ensure Storage Account HTTPS Only"
  - "Ensure Key Vault Purge Protection Enabled"

### `description`
- Markdown format starting with `## Description`
- Explain what the rule checks and what it fixes
- Keep it to 2-4 sentences

### `classifications`
- At least one `gomboc-ai/policy/*` classification is required
- Search `../../references/classifications.txt` for relevant classifications
- Common categories:
  - `gomboc-ai/policy/encryption/encryption_at_rest/...`
  - `gomboc-ai/policy/encryption/encryption_in_transit/...`
  - `gomboc-ai/policy/secure_networking/prevent_public_access_via_explicit_setting`
  - `gomboc-ai/policy/secure_management/accidental_deletion_protection/...`
  - `gomboc-ai/policy/logging_and_monitoring/...`

### `annotations`

| Key | Description | Example |
|-----|-------------|---------|
| `contributed-by` | Who created the rule | `community-user` |
| `gomboc-ai/provider` | Cloud provider | `AWS`, `Azure`, `GCP` |
| `gomboc-ai/resource` | Resource type from the IaC language | `aws_s3_bucket`, `Microsoft.Storage/storageAccounts`, `AWS::S3::Bucket` |
| `gomboc-ai/visibility` | Always `public` for community rules | `public` |
| `gomboc-ai/public-rule-bodies` | Always `"true"` for community rules | `"true"` |
| `gomboc-ai/description-plain` | One-line plaintext summary | `"Ensure S3 buckets have encryption enabled."` |

## Process

1. **Read the rule file** to understand what it audits and remediates
2. **Determine provider and resource** from the audit query
3. **Search classifications** by grepping `../../references/classifications.txt` for relevant keywords
4. **Generate metadata** following the field guidelines above
5. **Update the rule file** with the metadata in the `metadata:` section
6. **Validate** the rule file is still valid YAML (no syntax errors)

## Example

Before:
```yaml
metadata:
  name: gomboc-ai/ensure_s3_encryption
spec:
  ...
```

After:
```yaml
metadata:
  name: gomboc-ai/ensure_s3_encryption
  display_name: Ensure S3 Bucket Encryption at Rest
  description: |
    ## Description

    Ensures that AWS S3 buckets have server-side encryption enabled using AES-256 or AWS KMS.
  classifications:
    - gomboc-ai/policy/encryption/encryption_at_rest/encryption_at_rest_with_provider_managed_key
  annotations:
    contributed-by: community-user
    gomboc-ai/provider: AWS
    gomboc-ai/resource: aws_s3_bucket
    gomboc-ai/visibility: public
    gomboc-ai/public-rule-bodies: "true"
    gomboc-ai/description-plain: "Ensure AWS S3 buckets have server-side encryption enabled."
spec:
  ...
```
