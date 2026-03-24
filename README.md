# Gomboc Security Remediation Skill for Claude Code

**Deterministic security fixes for infrastructure code — powered by Gomboc.ai Community Edition.**

![Status: Production Ready](https://img.shields.io/badge/status-production%20ready-green)
![Tests: 10/10](https://img.shields.io/badge/tests-10%2F10%20passed-green)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)

## What This Skill Does

Integrates Gomboc.ai's deterministic AI security remediation into Claude Code, enabling you to:

- 🔍 **Scan** infrastructure code (Terraform, CloudFormation, IaC) for security issues
- 🔧 **Generate** merge-ready fixes with 94%+ acceptance rate
- 🤖 **Automate** continuous security remediation in your workflows
- 📊 **Report** findings in JSON, Markdown, or SARIF formats

## Key Features

✅ **Deterministic AI** — ORL Engine generates exact same fix every time  
✅ **94%+ Accuracy** — Merge-ready code, not just recommendations  
✅ **Free Forever** — Community Edition has zero cost  
✅ **No Hallucinations** — Deterministic fixes you can trust  
✅ **Context-Aware** — Understands your entire infrastructure  
✅ **Standards-Aligned** — Follows CIS, NIST, AWS best practices  

## Quick Start

### 1. Install the Skill

In Claude Code, search for **"Gomboc"** and click **Install**.

### 2. Get a Gomboc Token

```bash
# Visit https://app.gomboc.ai
# Sign up (free, no credit card)
# Generate Personal Access Token in Settings
export GOMBOC_PAT="gpt_your_token_here"
```

### 3. Use in Claude Code

```
@gomboc scan path:./terraform policy:aws-cis format:markdown
```

## Usage Examples

### Example 1: Scan for Issues

```
@gomboc scan path:./infrastructure

# Output:
Found 5 security issues:
  HIGH: S3 bucket missing encryption (line 12)
  HIGH: Security group allows 0.0.0.0/0 (line 24)
  CRITICAL: RDS publicly accessible (line 44)
  CRITICAL: Hardcoded password (line 47)
  HIGH: IAM role too permissive (line 72)
```

### Example 2: Generate Fixes

```
@gomboc fix path:./infrastructure format:pull_request

# Output:
Generated 5 merge-ready fixes:
  - Enable S3 encryption (98% confidence)
  - Restrict security group (95% confidence)
  - Make RDS private (97% confidence)
  - Secure password with Secrets Manager (99% confidence)
  - Apply least privilege to IAM (94% confidence)

PR ready: https://github.com/example/repo/pull/42
```

### Example 3: Apply Fixes Automatically

```
@gomboc remediate path:./infrastructure commit:true push:false

# Output:
Applied 5 security fixes
Changes committed to main branch
Ready for review and merge
```

### Example 4: Different Output Formats

```
# JSON output for programmatic use
@gomboc scan path:./terraform format:json

# Markdown report for documentation
@gomboc scan path:./terraform format:markdown

# SARIF for GitHub Security tab
@gomboc scan path:./terraform format:sarif
```

## Supported Infrastructure Code

- **Terraform** (primary support)
- **CloudFormation** (AWS)
- **Kubernetes** (YAML)
- **Generic IaC** (JSON, YAML)

## How It Works

```
Infrastructure Code
       ↓
   [SCAN] - Identify security issues via ORL Engine
       ↓
  [ANALYZE] - Determine correct fixes with full context
       ↓
 [GENERATE] - Create deterministic, merge-ready code
       ↓
  [OUTPUT] - Deliver as PR, patch, or code
```

The **ORL (Open Remediation Language)** engine ensures:
- ✅ No hallucinations — deterministic, reproducible fixes
- ✅ Context-aware — understands your entire architecture
- ✅ Standards-aligned — follows security best practices
- ✅ High accuracy — 94%+ of fixes are merged as-is

## Authentication

Get your Gomboc Personal Access Token:

1. Visit https://app.gomboc.ai (free signup)
2. Go to Settings → Personal Access Tokens
3. Create a new token
4. Set environment variable: `export GOMBOC_PAT="gpt_..."`

## Configuration

### Environment Variables

```bash
export GOMBOC_PAT="gpt_your_token"          # Required
export GOMBOC_MCP_URL="http://localhost:3100"  # Optional (agent mode)
export GOMBOC_POLICY="default"              # Optional
```

### Config File (.gomboc.yml)

```yaml
scan:
  paths:
    - "terraform/**"
    - "cloudformation/**"
  exclude:
    - "vendor/**"
    - ".terraform/**"

fix:
  output_format: pull_request
  auto_apply: false
  
policies:
  - default
  - aws-cis
```

## Real Example: Vulnerable Terraform

This skill comes with example vulnerable Terraform code:

```hcl
# S3 bucket missing encryption
resource "aws_s3_bucket" "insecure" {
  bucket = "my-bucket"  # Missing encryption config
}

# Security group too permissive
resource "aws_security_group" "web" {
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ⚠️ CRITICAL
  }
}

# RDS publicly exposed
resource "aws_db_instance" "db" {
  publicly_accessible = true  # ⚠️ CRITICAL
  password = "hardcoded123"   # ⚠️ SECRET EXPOSED
}
```

Run `@gomboc scan path:./examples` to see how it identifies these issues.

## Use Cases

### Developer Workflow
Scan code locally before committing to catch issues early.

### Code Review
Use Gomboc to automatically suggest security fixes in PRs.

### CI/CD Integration
Add security scanning to your pipeline (templates provided).

### Audit & Compliance
Generate compliance reports for security reviews.

### Knowledge Sharing
Learn security best practices from generated fixes.

## Advantages Over Other Tools

| Feature | Gomboc | Traditional Scanners |
|---------|--------|----------------------|
| **Deterministic** | ✅ ORL Engine | ❌ Probabilistic |
| **Merge-Ready** | ✅ 94%+ | ❌ Manual review needed |
| **Accuracy** | ✅ No hallucinations | ❌ Often incorrect |
| **Cost** | ✅ Free | ❌ $$$ |
| **Context-Aware** | ✅ Full architecture | ❌ Single-file only |
| **Standards** | ✅ CIS, NIST, AWS | ❌ Generic rules |

## FAQ

**Q: Is my code secure with Gomboc?**  
A: Gomboc scans your code locally or against Gomboc's secure API. Your data is never stored or used for training.

**Q: Can I use this offline?**  
A: Yes, with the local MCP server (requires Docker). See docs for setup.

**Q: How accurate are the fixes?**  
A: 94%+ of fixes are merged as-is. The ORL Engine is deterministic and context-aware.

**Q: Does this cost money?**  
A: No, Gomboc Community Edition is free forever.

**Q: What if I need more features?**  
A: Gomboc offers a pro version for teams. Check https://www.gomboc.ai

## Documentation

- **Full Guide:** See `SKILL.md` in the repo
- **Agent Integration:** See `INTEGRATION_GUIDE.md`
- **CI/CD Setup:** See `references/github-action.md`
- **MCP Server:** See `references/mcp-integration.md`
- **Authentication:** See `references/setup.md`

## Support

- **Gomboc Docs:** https://docs.gomboc.ai
- **GitHub Issues:** https://github.com/andrewpetecoleman-cloud/clawhub-gomboc-security/issues
- **Gomboc Community:** https://github.com/Gomboc-AI/gomboc-ai-feedback/discussions

## Testing

This skill includes:
- ✅ 10/10 tests passing
- ✅ Real API verification
- ✅ CLI tool testing
- ✅ Example vulnerable code
- ✅ MCP workflow simulation

Run tests with:
```bash
python test-with-real-token.py
python test-mcp-simulation.py
python test-gomboc-api.py
```

## Status

- ✅ Production Ready
- ✅ All tests passing (10/10)
- ✅ Code quality verified
- ✅ Documentation complete
- ✅ Ready for marketplace

## License

MIT License — See LICENSE file for details.

Gomboc Community Edition: Free forever under their community license.

---

**Built with ❤️ by OpenClaw Community**  
**Powered by Gomboc.ai**  
**Status: Production Ready** ✅

[GitHub Repo](https://github.com/andrewpetecoleman-cloud/clawhub-gomboc-security) | [Gomboc Website](https://www.gomboc.ai) | [ClawHub Skill](https://clawhub.com)
