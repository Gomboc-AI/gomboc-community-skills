#!/usr/bin/env python3
"""
submit_orl_report.py — submit an `orl remediate` report to the Gomboc Integrations service.

Reads an orl report (YAML straight from `orl remediate --out report.yaml`, or JSON), converts
it to JSON, and invokes the Node SDK helper `submit-orl-report.mjs` (which builds the
createOrlReportEvent body with requestOrigin=CODE_AGENT and POSTs via @gomboc-ai/gomboc-node-sdk).

Auth: GOMBOC_PAT environment variable (the community plugin's Frontegg JWT). Falls back to
GOMBOC_ACCESS_TOKEN and GOMBOC_API_TOKEN.

NON-BLOCKING by design: a missing report, PyYAML, node, the SDK, or token is logged and exits
0 — it must never break an apply-fix workflow.

Usage:
  python3 submit_orl_report.py --report <orl-report.yaml|json> [--workspace P] [--branch B]
                               [--duration S] [--repo owner/name] [--request-origin CODE_AGENT]
                               [--pr-url U --pr-id I --pr-author A] [--dry-run]
"""
import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
NODE_SUBMITTER = HERE / "submit-orl-report.mjs"


def _skip(msg: str) -> int:
    print(f"submit_orl_report: {msg} — skipping (non-blocking).", file=sys.stderr)
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--report", required=True)
    ap.add_argument("--workspace", default=".")
    ap.add_argument("--branch", default="")
    ap.add_argument("--duration", default="0")
    ap.add_argument("--repo", default=None)
    ap.add_argument("--commit", default=None,
                    help="Code-state commit SHA for the scan-uniqueness key (auto-resolved from "
                         "--workspace git HEAD if omitted).")
    ap.add_argument("--request-origin", default="CODE_AGENT")
    ap.add_argument("--force", action="store_true",
                    help="Bypass the client-side duplicate guard and re-submit the scan.")
    ap.add_argument("--pr-url", default=None)
    ap.add_argument("--pr-id", default=None)
    ap.add_argument("--pr-author", default=None)
    ap.add_argument("--dry-run", action="store_true")
    a = ap.parse_args()

    rep = Path(a.report)
    if not rep.exists():
        return _skip(f"no report at {rep}")

    # Load YAML (orl's native --out format) or JSON.
    try:
        text = rep.read_text()
        if rep.suffix.lower() in (".yaml", ".yml"):
            try:
                import yaml
            except ImportError:
                return _skip("PyYAML not installed (pip install pyyaml)")
            doc = next((d for d in yaml.safe_load_all(text) if d), None)
        else:
            doc = json.loads(text)
    except Exception as e:
        return _skip(f"could not parse {rep} ({e})")
    if not doc:
        return _skip(f"empty report {rep}")

    if not NODE_SUBMITTER.exists():
        return _skip(f"node submitter missing at {NODE_SUBMITTER}")
    if not shutil.which("node"):
        return _skip("node not installed")

    rj = rep.with_suffix(".submit.json")
    try:
        # default=str: orl reports embed datetimes that PyYAML parses into datetime objects.
        rj.write_text(json.dumps(doc, default=str))
    except Exception as e:
        return _skip(f"could not stage JSON ({e})")

    # Resolve the code-state commit SHA from the workspace git HEAD.
    commit = a.commit
    if not commit and a.workspace:
        try:
            commit = subprocess.run(["git", "-C", a.workspace, "rev-parse", "HEAD"],
                                    capture_output=True, text=True, timeout=10).stdout.strip()
        except Exception:
            commit = ""

    argv = ["node", str(NODE_SUBMITTER), "--report", str(rj),
            "--workspace", a.workspace, "--branch", a.branch,
            "--duration", str(a.duration), "--request-origin", a.request_origin]
    if commit:
        argv += ["--commit", commit]
    for flag, val in (("--repo", a.repo), ("--pr-url", a.pr_url),
                      ("--pr-id", a.pr_id), ("--pr-author", a.pr_author)):
        if val:
            argv += [flag, val]
    if a.dry_run:
        argv.append("--dry-run")
    if a.force:
        argv.append("--force")
    try:
        subprocess.run(argv, timeout=60)
    except Exception as e:
        return _skip(f"submitter invocation failed ({e})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
