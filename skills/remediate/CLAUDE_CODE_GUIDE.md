# Claude Code Integration Guide

Use Gomboc directly in Claude Code to scan and fix infrastructure code.

## Installation

1. Open Claude Code
2. Click **Skills** or **Extensions**
3. Search for **"Gomboc"**
4. Click **Install**

The skill is now available for use.

## Authentication

### Step 1: Get a Gomboc Token

```bash
# Visit https://app.gomboc.ai
# Sign up (free, no credit card needed)
# Go to Settings → Personal Access Tokens
# Click "Generate Token"
# Copy the token (format: gpt_xyz123...)
```

### Step 2: Set Environment Variable

```bash
export GOMBOC_PAT="gpt_your_token_here"
```

Or set it in Claude Code settings:
- Open Claude Code preferences
- Search for "Gomboc"
- Enter your token in the GOMBOC_PAT field

## Basic Commands

### Scan for Issues

```
@gomboc scan path:./terraform
```

Returns list of security issues with severity levels.

**Optional parameters:**
- `policy:aws-cis` — Apply AWS CIS policy
- `format:markdown` — Output as markdown (default: json)

### Generate Fixes

```
@gomboc fix path:./terraform format:pull_request
```

Returns merge-ready fixes with confidence scores.

**Optional parameters:**
- `policy:default` — Security policy (default, aws-cis)
- `format:patch` — Output as patch file
- `apply:true` — Apply fixes automatically (use with caution)

### Apply Fixes

```
@gomboc remediate path:./terraform commit:true
```

Directly applies fixes to code files.

**Optional parameters:**
- `commit:true` — Auto-commit changes
- `push:true` — Push to remote (requires git config)

## Real Examples

### Example 1: Scan Terraform Directory

**Command:**
```
@gomboc scan path:./infrastructure/prod
```

**Output:**
```
🔍 Scanning ./infrastructure/prod...

Found 5 security issues:

[CRITICAL] RDS Database Exposed to Internet
  File: database.tf (line 44)
  Description: publicly_accessible = true
  Fix: Set to false and place in private subnet

[CRITICAL] Hardcoded Database Password
  File: database.tf (line 47)
  Description: password hardcoded in code
  Fix: Use AWS Secrets Manager

[HIGH] S3 Bucket Missing Encryption
  File: s3.tf (line 12)
  Description: No encryption at rest configured
  Fix: Add server_side_encryption_configuration

[HIGH] Security Group Too Permissive
  File: security.tf (line 24)
  Description: Allows all inbound traffic (0.0.0.0/0)
  Fix: Restrict to known CIDR blocks

[HIGH] IAM Role Too Permissive
  File: iam.tf (line 72)
  Description: Policy grants Action: * on all resources
  Fix: Apply principle of least privilege
```

### Example 2: Get Markdown Report

**Command:**
```
@gomboc scan path:./terraform format:markdown
```

**Output:**
```markdown
# Security Scan Results

## Issues Found: 5

### CRITICAL Issues

#### RDS Database Exposed to Internet
- File: database.tf:44
- Type: Infrastructure Risk
- Severity: CRITICAL (99% confidence)
- Remediation: Set publicly_accessible = false

#### Hardcoded Database Password
- File: database.tf:47
- Type: Secret Exposure
- Severity: CRITICAL (99% confidence)
- Remediation: Use AWS Secrets Manager or terraform variables

### HIGH Issues

[... more issues ...]

## Summary

- CRITICAL: 2
- HIGH: 3
- MEDIUM: 0
- LOW: 0

**Recommendation:** Fix critical issues immediately
```

### Example 3: Generate Fixes with High Confidence

**Command:**
```
@gomboc fix path:./terraform format:pull_request
```

**Output:**
```
🔧 Generating fixes...

Generated 5 security fixes:

1. Make RDS Database Private
   Confidence: 97%
   File: database.tf
   Status: Ready for review
   
   proposed_changes:
   ```hcl
   publicly_accessible = false
   
   db_subnet_group_name = aws_db_subnet_group.private.name
   ```

2. Secure Database Password
   Confidence: 99%
   File: database.tf
   Status: Ready for review
   
   proposed_changes:
   ```hcl
   password = random_password.db_password.result
   
   resource "aws_secretsmanager_secret" "db_password" {
     name = "rds/prod/password"
   }
   ```

3. Enable S3 Encryption
   Confidence: 98%
   File: s3.tf
   Status: Ready for review
   
   proposed_changes:
   ```hcl
   resource "aws_s3_bucket_server_side_encryption_configuration" {
     bucket = aws_s3_bucket.main.id
     rule {
       apply_server_side_encryption_by_default {
         sse_algorithm = "AES256"
       }
     }
   }
   ```

4. Restrict Security Group
   Confidence: 95%
   File: security.tf
   Status: Ready for review
   
   proposed_changes:
   ```hcl
   ingress {
     from_port   = 443
     to_port     = 443
     protocol    = "tcp"
     cidr_blocks = ["10.0.0.0/8"]  # Internal network only
   }
   ```

5. Apply Least Privilege to IAM
   Confidence: 94%
   File: iam.tf
   Status: Ready for review
   
   proposed_changes:
   ```hcl
   policy = jsonencode({
     Version = "2012-10-17"
     Statement = [{
       Effect = "Allow"
       Action = [
         "s3:GetObject",
         "s3:PutObject",
         "dynamodb:Query"
       ]
       Resource = [...]
     }]
   })
   ```

📦 Pull Request Ready
Title: "Security: Auto-remediate infrastructure issues"
URL: https://github.com/example/repo/pull/42
```

### Example 4: Analyze with AWS CIS Policy

**Command:**
```
@gomboc scan path:./prod policy:aws-cis format:markdown
```

**Output:**
Uses AWS CIS Foundations Benchmark to identify compliance issues.

### Example 5: Apply Fixes with Auto-Commit

**Command:**
```
@gomboc remediate path:./infrastructure commit:true push:false
```

**Output:**
```
🔧 Applying 5 security fixes...

✅ Fixed: database.tf (RDS made private)
✅ Fixed: database.tf (Password secured)
✅ Fixed: s3.tf (Encryption enabled)
✅ Fixed: security.tf (CIDR restricted)
✅ Fixed: iam.tf (Permissions restricted)

📝 Changes committed to main branch
   Commit: "Security: Auto-remediate infrastructure issues"
   Files modified: 5
   
Ready for: git push
```

## Advanced Usage

### Scanning Specific File Types

```
@gomboc scan path:./terraform/*.tf
```

### Excluding Paths

```
@gomboc scan path:./infrastructure exclude:vendor/**,.terraform/**
```

### Dry Run (Show Fixes Without Applying)

```
@gomboc fix path:./infrastructure apply:false
```

### Get JSON Output for Programmatic Use

```
@gomboc scan path:./terraform format:json
```

Returns structured JSON:
```json
{
  "scan_id": "scan_abc123",
  "issue_count": 5,
  "issues": [
    {
      "id": "issue_1",
      "severity": "CRITICAL",
      "title": "RDS Publicly Accessible",
      "confidence": 0.99,
      "file": "database.tf",
      "line": 44
    }
  ]
}
```

## Tips & Best Practices

### 1. Start with Dry Run

Always scan first to see what you're fixing:

```
@gomboc scan path:./infrastructure format:markdown
```

Then generate fixes without applying:

```
@gomboc fix path:./infrastructure apply:false
```

### 2. Use for Code Review

In Claude Code code review mode:

```
Reviewer: @gomboc scan path:./infrastructure policy:aws-cis

This will highlight security issues in the PR.
```

### 3. Iterate on Policies

Try different policies to find the right one:

```
@gomboc scan path:./terraform policy:default
@gomboc scan path:./terraform policy:aws-cis
```

### 4. Check Before Committing

Use as a pre-commit check:

```
@gomboc scan path:. format:json

If issue_count > 0:
  Fix with: @gomboc fix path:. format:pull_request
```

### 5. Document Findings

Export to markdown for team review:

```
@gomboc scan path:./infrastructure format:markdown

[Copy-paste into documentation or PR comment]
```

## Troubleshooting

### "GOMBOC_PAT not set"

**Error:** Gomboc token not configured

**Fix:**
```bash
export GOMBOC_PAT="gpt_your_token"
```

Or set in Claude Code preferences → Gomboc → GOMBOC_PAT

### "Authentication failed"

**Error:** Token is invalid or expired

**Fix:**
1. Go to https://app.gomboc.ai
2. Generate a new Personal Access Token
3. Update: `export GOMBOC_PAT="new_token"`

### "Connection refused"

**Error:** Can't reach Gomboc API

**Fix:**
- Check internet connection
- Verify Gomboc is not down (check status.gomboc.ai)
- Try again in a few moments

### "No issues found"

**Reason:** Your code might be secure, or Gomboc doesn't scan those files

**Fix:**
- Check file extensions (.tf, .json, .yaml for IaC)
- Try example files: `@gomboc scan path:./examples`

## Performance

Typical performance:
- **Scanning:** 1-5 seconds per 100 files
- **Fix generation:** 2-10 seconds per scan
- **Applying fixes:** < 5 seconds

Large codebases:
- Use `path:./specific/directory` to limit scope
- Scan modules separately

## Security & Privacy

- ✅ Code is scanned by Gomboc's secure API
- ✅ Your code is NOT stored or used for training
- ✅ Token is stored locally in Claude Code settings
- ✅ All communication is HTTPS encrypted
- ✅ See Gomboc privacy policy: https://www.gomboc.ai/privacy

## Getting Help

- **Documentation:** https://docs.gomboc.ai
- **GitHub Issues:** https://github.com/andrewpetecoleman-cloud/clawhub-gomboc-security/issues
- **Community:** https://github.com/Gomboc-AI/gomboc-ai-feedback/discussions

## Next Steps

1. ✅ Install the skill
2. ✅ Get your Gomboc token
3. ✅ Try: `@gomboc scan path:./examples`
4. ✅ Review results
5. ✅ Generate fixes: `@gomboc fix path:./examples`
6. ✅ Apply to your infrastructure

---

**Ready to secure your infrastructure? Start with `@gomboc scan` today!** 🚀
