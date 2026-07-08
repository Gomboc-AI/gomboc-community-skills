#!/usr/bin/env node
/**
 * submit-orl-report.mjs — submit one `orl remediate` report to the Gomboc Integrations service.
 *
 * Mirrors Gomboc-AI/actions PR #47 (normalize-report.ts + build-orl-report-event.ts +
 * post-integrations.ts), adapted for gomboc-community-skills: requestOrigin=CODE_AGENT,
 * reads a JSON-ified orl report, and is fully NON-BLOCKING — any missing dependency, token,
 * or network/API error logs a warning and exits 0 so it never breaks a fix workflow.
 *
 * Auth: GOMBOC_PAT (the community plugin PAT, a Frontegg JWT carrying `tenantId`) —
 * falls back to GOMBOC_ACCESS_TOKEN, then GOMBOC_API_TOKEN.
 * Endpoint: INTEGRATIONS_SERVICE_URL (default https://integrations.app.gomboc.ai).
 *
 * Usage:
 *   node submit-orl-report.mjs --report <orl-report.json> [options]
 * Options:
 *   --report <path>        REQUIRED. orl remediate report as JSON ({type:Report, metadata, spec}).
 *   --workspace <path>     Reported workspace/path (default: report spec.workspace or ".").
 *   --branch <name>        Branch the remediation landed on.
 *   --duration <seconds>   Wall-clock seconds for the orl remediate call (default 0).
 *   --repo <owner/name>    GitHub repo slug (enables scmContext when a PR is also supplied).
 *   --pr-url <url> --pr-id <id> --pr-author <login>   Resulting PR (when already opened).
 *   --request-origin <v>   GITHUB_ACTION|IDE|MCP|CODE_AGENT (default CODE_AGENT).
 *   --effect <v>           default "SubmitForReview".
 *   --dry-run              Build + print the request body; do not import the SDK or POST.
 */
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { createHash } from 'node:crypto';

const DEFAULT_BASE_URL = 'https://integrations.app.gomboc.ai';

// ---- client-side duplicate guard ----
// The Integrations report endpoint has no server-side idempotency (a second POST of the same scan is
// accepted, confirmed live), so we keep a local ledger of submitted scanIds and refuse to re-send one.
// Override the path with GOMBOC_SCAN_LEDGER; bypass the guard with --force.
function ledgerPath() {
  return process.env.GOMBOC_SCAN_LEDGER || path.join(os.homedir(), '.gomboc', 'submitted-scans.json');
}
function ledgerHas(scanId) {
  try {
    const d = JSON.parse(fs.readFileSync(ledgerPath(), 'utf8'));
    return Array.isArray(d?.scans) && d.scans.includes(scanId);
  } catch { return false; }
}
function ledgerAdd(scanId) {
  try {
    const p = ledgerPath();
    fs.mkdirSync(path.dirname(p), { recursive: true });
    let d = { scans: [] };
    try { d = JSON.parse(fs.readFileSync(p, 'utf8')); } catch { /* fresh */ }
    if (!Array.isArray(d.scans)) d.scans = [];
    if (!d.scans.includes(scanId)) d.scans.push(scanId);
    if (d.scans.length > 5000) d.scans = d.scans.slice(-5000);  // bound growth
    fs.writeFileSync(p, JSON.stringify(d));
  } catch { /* non-fatal */ }
}

function warn(msg) { console.warn(`submit-orl-report: ${msg}`); }
function skip(msg) { warn(`${msg} — skipping submission (non-blocking).`); process.exit(0); }

function parseArgs(argv) {
  const a = {};
  for (let i = 0; i < argv.length; i++) {
    const t = argv[i];
    if (!t.startsWith('--')) continue;
    const key = t.slice(2);
    const next = argv[i + 1];
    if (next === undefined || next.startsWith('--')) { a[key] = true; }
    else { a[key] = next; i++; }
  }
  return a;
}

// ---- JWT tenantId (ports lib/jwt.ts) ----
function tenantIdFromToken(token) {
  const parts = String(token || '').split('.');
  if (parts.length < 2) return null;
  try {
    const b64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const padded = b64 + '='.repeat((4 - (b64.length % 4)) % 4);
    const payload = JSON.parse(Buffer.from(padded, 'base64').toString('utf8'));
    const t = payload?.tenantId;
    return typeof t === 'string' && t.length ? t : null;
  } catch { return null; }
}

// ---- normalize orl report (ports normalize-report.ts) ----
const DROP_ANNOTATION_KEYS = ['example', 'graph', 'code-fix-id', 'resource-key',
  'risk/statement', 'impact/statement'];

function trimDescription(desc, max = 500) {
  if (!desc) return undefined;
  return desc.length > max ? desc.slice(0, max) + '…' : desc;
}

// Cap + truncate the errors array so a large scan doesn't blow the Integrations request-size limit.
// The true count is preserved separately on `errorsTotal`.
function trimErrors(errors, max = 25, maxMsg = 500) {
  if (!Array.isArray(errors)) return [];
  return errors.slice(0, max).map((e) => {
    if (e && typeof e === 'object' && typeof e.message === 'string' && e.message.length > maxMsg) {
      return { ...e, message: e.message.slice(0, maxMsg) + '…' };
    }
    return e;
  });
}

// Parse orl's Go-format duration string (spec.duration, present in orl >= v1.3.9), e.g.
// "21.519625ms", "1.5s", "3m2.5s", "1h2m3s", "500µs". Returns seconds, or null if absent/unparseable.
function parseGoDuration(s) {
  if (typeof s !== 'string' || !s.trim()) return null;
  const mult = { ns: 1e-9, us: 1e-6, 'µs': 1e-6, 'μs': 1e-6, ms: 1e-3, s: 1, m: 60, h: 3600 };
  const re = /([0-9]*\.?[0-9]+)(ns|us|µs|μs|ms|s|m|h)/g;
  let total = 0, matched = false, m;
  while ((m = re.exec(s)) !== null) {
    const u = mult[m[2]];
    if (u === undefined) continue;
    total += parseFloat(m[1]) * u;
    matched = true;
  }
  return matched ? Math.round(total * 1000) / 1000 : null;
}

function totalsFromReport(spec) {
  const rules = Array.isArray(spec.rules) ? spec.rules : [];
  const sum = (k) => rules.reduce((n, r) => n + (Number(r?.[k]) || 0), 0);
  return {
    findings: spec.findings ?? sum('findings'),
    fixes: spec.fixes ?? sum('fixes'),
    changes: spec.changes ?? sum('changes'),
  };
}

function normalizeOrlReport(report) {
  const spec = report.spec || {};
  const totals = totalsFromReport(spec);
  const display = report.metadata?.display_name?.trim();
  const metadata = {
    name: report.metadata?.name ?? 'orl-report',
    ...(trimDescription(report.metadata?.description) ? { description: trimDescription(report.metadata.description) } : {}),
    ...(display ? { annotations: { display_name: display } } : {}),
  };
  return {
    type: 'Report',
    version: 'v1',
    metadata,
    workspace: spec.workspace ?? '.',
    language: spec.language ?? 'unknown',
    rules_applied: spec.rules_applied ?? (Array.isArray(spec.rules) ? spec.rules.length : 0),
    findings: totals.findings,
    fixes: totals.fixes,
    changes: totals.changes,
    rules: [],                       // keep the payload lean.
    errors: trimErrors(spec.errors),
    errorsTotal: Array.isArray(spec.errors) ? spec.errors.length : 0,
    ...(spec.duration !== undefined ? { duration: spec.duration } : {}),
    ...(spec.rules_skipped !== undefined ? { rules_skipped: spec.rules_skipped } : {}),
    ...(spec.resolved_location_count !== undefined ? { resolved_location_count: spec.resolved_location_count } : {}),
  };
}

// ---- deterministic scan identity (uniqueness key for server-side dedup) ----
function computeScanId(a, orlReport) {
  const repoKey = a.repo || (a.workspace ? String(a.workspace).split('/').filter(Boolean).pop() : '') || 'workspace';
  const identity = [
    repoKey,
    a.commit || '',
    a.branch || '',
    a['request-origin'] || 'CODE_AGENT',
    orlReport.language,
    orlReport.rules_applied,
    orlReport.findings,
    orlReport.fixes,
    orlReport.changes,
  ];
  return createHash('sha256').update(JSON.stringify(identity)).digest('hex');
}

// ---- build request body ----
// useV2=true → V2 body format (version: 2, /v2/reporting/orl-external, richer scmContext)
// useV2=false → V1 body format (version: 1.0, /reporting/orl-external, legacy scmContext)
// Prefer V2; fall back to V1 when the installed SDK < 2.2.1 lacks createOrlReportEventV2.
function buildBody(a, orlReport, useV2 = true) {
  const body = {
    version: useV2 ? 2 : 1.0,
    requestOrigin: a['request-origin'] || 'CODE_AGENT',
    effect: a.effect || 'SubmitForReview',
    reports: [{
      path: a.workspace || orlReport.workspace || '.',
      branch: a.branch || '',
      orlReport,
    }],
    errors: [],
    durationInSeconds: Math.round(Math.max(0, Number(a.duration) || 0)),
  };
  // scmContext is optional; include it only when we have a resulting PR to reference.
  if (a.repo && a['pr-url'] && a['pr-id']) {
    if (useV2) {
      const [ownerName = '', repositoryName = ''] = String(a.repo).split('/');
      body.scmContext = {
        scmType: 'GITHUB',
        resultingPullRequest: {
          repositoryId: '',
          repositoryName,
          ownerId: '',
          ownerName,
          number: String(a['pr-id']),
          url: a['pr-url'],
          title: '',
          sourceBranch: a.branch || '',
          targetBranch: '',
          status: 'OPEN',
          provider: 'GitHub',
        },
      };
    } else {
      body.scmContext = {
        scmType: 'GITHUB',
        resultingPullRequest: { id: String(a['pr-id']), url: a['pr-url'], author: a['pr-author'] || '' },
      };
    }
  }
  return body;
}

async function main() {
  const a = parseArgs(process.argv.slice(2));
  if (!a.report) skip('no --report path given');
  let report;
  try { report = JSON.parse(fs.readFileSync(a.report, 'utf8')); }
  catch (e) { skip(`could not read/parse report ${a.report}: ${e.message}`); }

  const orlReport = normalizeOrlReport(report);
  const reportDur = parseGoDuration(report?.spec?.duration);
  if (reportDur != null) a.duration = reportDur;
  orlReport.scanId = computeScanId(a, orlReport);
  if (a.commit) orlReport.commit = a.commit;

  if (a['dry-run']) {
    console.log(JSON.stringify(buildBody(a, orlReport, true), null, 2));
    return;
  }

  if (!a.force && ledgerHas(orlReport.scanId)) {
    console.log(`submit-orl-report: scan ${orlReport.scanId.slice(0, 12)} already submitted — `
      + `rejecting as duplicate (client-side; pass --force to override).`);
    process.exit(0);
  }

  // Auth: GOMBOC_PAT is the primary token for community skills (Frontegg JWT with tenantId).
  const token = process.env.GOMBOC_PAT
             || process.env.GOMBOC_ACCESS_TOKEN
             || process.env.GOMBOC_API_TOKEN;
  if (!token) skip('GOMBOC_PAT / GOMBOC_ACCESS_TOKEN / GOMBOC_API_TOKEN not set');
  const accountId = tenantIdFromToken(token);
  if (!accountId) skip('access token has no tenantId claim (need a Gomboc JWT — set GOMBOC_PAT)');
  const baseUrl = (process.env.INTEGRATIONS_SERVICE_URL || DEFAULT_BASE_URL).replace(/\/$/, '');

  let mod;
  try {
    mod = await import('@gomboc-ai/gomboc-node-sdk');
  } catch (e) {
    skip(`@gomboc-ai/gomboc-node-sdk not installed (run \`npm install\` in scripts/integrations): ${e.message}`);
  }
  const initIntegrationsServiceSdk = mod.initIntegrationsServiceSdk ?? mod.default?.initIntegrationsServiceSdk;
  if (typeof initIntegrationsServiceSdk !== 'function') {
    skip('SDK loaded but initIntegrationsServiceSdk export not found (unexpected SDK version)');
  }

  try {
    const sdk = await initIntegrationsServiceSdk({ accessToken: token, accountId, baseUrl, logger: console });
    // Prefer V2 (SDK >= 2.2.1); fall back to V1 transparently when running an older SDK.
    const useV2 = typeof sdk.createOrlReportEventV2 === 'function';
    if (!useV2 && typeof sdk.createOrlReportEvent !== 'function') {
      skip('SDK has neither createOrlReportEventV2 nor createOrlReportEvent (unexpected SDK version)');
    }
    const body = buildBody(a, orlReport, useV2);
    const result = useV2
      ? await sdk.createOrlReportEventV2(body)
      : await sdk.createOrlReportEvent(body);
    if (result?.isOk?.()) {
      ledgerAdd(orlReport.scanId);
      const d = useV2 ? (result.value?.data ?? {}) : (result.value ?? {});
      console.log(`submit-orl-report: submitted scan ${orlReport.scanId.slice(0, 12)} `
        + `(${orlReport.findings} findings, ${orlReport.fixes} fixes) to ${baseUrl}`
        + (d.jobId ? ` [jobId=${d.jobId}]` : '')
        + (d.message ? ` — ${d.message}` : '')
        + (d.success === false ? ' [success=false]' : ''));
    } else {
      const err = result?.error ?? {};
      const status = err.statusCode ?? '?';
      const dup = status === 409 || /duplicat/i.test(JSON.stringify(err));
      warn(`Integrations POST ${dup ? 'rejected as duplicate' : 'failed'} (${status}) for scan `
        + `${orlReport.scanId.slice(0, 12)}: ${JSON.stringify(err).slice(0, 300)} — non-blocking.`);
    }
  } catch (e) {
    warn(`submission error: ${e.message} — non-blocking.`);
  }
  process.exit(0);
}

main();
