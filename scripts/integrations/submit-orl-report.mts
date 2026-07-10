/**
 * submit-orl-report.mts — submit one `orl remediate` report to Gomboc Integrations V2.
 *
 * TypeScript source; compiled to submit-orl-report.mjs via `npm run build`.
 *
 * Parses YAML or JSON orl reports, collects git diffs and remediated file content
 * from the workspace, and POSTs to /v2/reporting/orl-external via createOrlReportEventV2.
 * Always exits 0 — submission failures are warnings, never blockers.
 *
 * Auth: GOMBOC_PAT (community plugin PAT) — falls back to GOMBOC_ACCESS_TOKEN, then GOMBOC_API_TOKEN.
 * Endpoint: INTEGRATIONS_SERVICE_URL (default https://integrations.app.gomboc.ai).
 *
 * Usage:
 *   node submit-orl-report.mjs --report <path> [options]
 * Options:
 *   --report <path>       REQUIRED. Path to orl remediate report (YAML or JSON).
 *   --workspace <path>    Workspace that was remediated (default: spec.workspace or ".").
 *   --branch <name>       Branch the remediation ran on.
 *   --duration <seconds>  Wall-clock seconds (overridden by spec.duration when present).
 *   --repo <owner/name>   GitHub repo slug — populates scmContext resultingPullRequest.
 *   --pr-url <url>        Resulting PR URL.
 *   --pr-id <id>          Resulting PR number.
 *   --pr-author <login>   PR author login.
 *   --request-origin <v>  GITHUB_ACTION|IDE|MCP|CODE_AGENT (default: CODE_AGENT).
 *   --effect <v>          Default: SubmitForReview.
 *   --dry-run             Print request body without posting.
 *   --force               Bypass client-side duplicate guard.
 */
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import yaml from 'yaml';
import {
  initIntegrationsServiceSdk,
  type IIntegrationsServiceSdk,
} from '@gomboc-ai/gomboc-node-sdk';

// ── SDK-derived types ────────────────────────────────────────────────────────

type V2Body = Parameters<IIntegrationsServiceSdk['createOrlReportEventV2']>[0];
type IntegrationsOrlReport = NonNullable<V2Body['reports'][number]['orlReport']>;
type IntegrationsOrlReportRule = IntegrationsOrlReport['rules'][number];
type IntegrationsOrlFindingLocation = NonNullable<IntegrationsOrlReportRule['findingLocations']>[number];
type IntegrationsLocation = NonNullable<IntegrationsOrlFindingLocation['originalLocation']>;
type ResolutionStatus = NonNullable<IntegrationsOrlFindingLocation['resolutionStatus']>;

// ── ORL YAML report types ────────────────────────────────────────────────────

type OrlLocation = {
  id?: string;
  file_path: string;
  start_line: number;
  end_line?: number;
  start_column?: number;
  end_column?: number;
};

type OrlFindingLocationRow = {
  id: string;
  original_location?: OrlLocation;
  resolved_location?: OrlLocation;
  resolution_status?: string;
  remediated?: boolean;
  remediateable?: boolean;
  message?: string;
  level?: string;
};

type OrlReportRule = {
  name: string;
  findings?: number;
  fixes?: number;
  changes?: number;
  files?: Array<{ path: string }>;
  files_changed?: Record<string, unknown>;
  finding_locations?: OrlFindingLocationRow[];
  errors?: unknown[];
  metadata?: {
    name?: string;
    display_name?: string;
    description?: string;
    priority?: number;
    skip?: boolean;
    required_contexts?: string[];
    classifications?: string[];
    annotations?: Record<string, string>;
  };
};

type OrlReport = {
  type?: string;
  version?: string;
  metadata: {
    name: string;
    display_name?: string;
    description?: string;
    annotations?: Record<string, string>;
  };
  spec: {
    workspace?: string;
    language?: string;
    rules_applied?: number;
    rules_skipped?: number;
    findings?: number;
    fixes?: number;
    changes?: number;
    duration?: string;
    resolved_location_count?: number;
    files_changed?: Record<string, unknown>;
    errors?: unknown[];
    rules?: OrlReportRule[];
  };
};

// ── CLI args ─────────────────────────────────────────────────────────────────

type RequestOrigin = 'GITHUB_ACTION' | 'IDE' | 'MCP' | 'CODE_AGENT';

type CliArgs = {
  report?: string;
  workspace?: string;
  branch?: string;
  duration?: string;
  repo?: string;
  'pr-url'?: string;
  'pr-id'?: string;
  'pr-author'?: string;
  'request-origin'?: RequestOrigin;
  effect?: string;
  force?: boolean;
  'dry-run'?: boolean;
};

// ── Client-side duplicate guard ───────────────────────────────────────────────

function ledgerPath(): string {
  return process.env.GOMBOC_SCAN_LEDGER ?? path.join(os.homedir(), '.gomboc', 'submitted-scans.json');
}

function ledgerHas(scanId: string): boolean {
  try {
    const d = JSON.parse(fs.readFileSync(ledgerPath(), 'utf8')) as { scans?: unknown[] };
    return Array.isArray(d.scans) && d.scans.includes(scanId);
  } catch { return false; }
}

function ledgerAdd(scanId: string): void {
  try {
    const p = ledgerPath();
    fs.mkdirSync(path.dirname(p), { recursive: true });
    let d: { scans: string[] } = { scans: [] };
    try { d = JSON.parse(fs.readFileSync(p, 'utf8')) as { scans: string[] }; } catch { /* fresh */ }
    if (!Array.isArray(d.scans)) d.scans = [];
    if (!d.scans.includes(scanId)) d.scans.push(scanId);
    if (d.scans.length > 5000) d.scans = d.scans.slice(-5000);
    fs.writeFileSync(p, JSON.stringify(d));
  } catch { /* non-fatal */ }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function warn(msg: string): void { console.warn(`submit-orl-report: ${msg}`); }

function skip(msg: string): never {
  warn(`${msg} — skipping submission (non-blocking).`);
  process.exit(0);
}

function parseArgs(argv: string[]): CliArgs {
  const a: Record<string, string | boolean> = {};
  for (let i = 0; i < argv.length; i++) {
    const t = argv[i];
    if (!t.startsWith('--')) continue;
    const key = t.slice(2);
    const next = argv[i + 1];
    if (next === undefined || next.startsWith('--')) { a[key] = true; }
    else { a[key] = next; i++; }
  }
  return a as CliArgs;
}

function tenantIdFromToken(token: string): string | null {
  const parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    const b64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
    const padded = b64 + '='.repeat((4 - (b64.length % 4)) % 4);
    const payload = JSON.parse(Buffer.from(padded, 'base64').toString('utf8')) as Record<string, unknown>;
    const t = payload['tenantId'];
    return typeof t === 'string' && t.length > 0 ? t : null;
  } catch { return null; }
}

function parseGoDuration(s: string | undefined): number | null {
  if (typeof s !== 'string' || !s.trim()) return null;
  const mult: Record<string, number> = { ns: 1e-9, us: 1e-6, 'µs': 1e-6, 'μs': 1e-6, ms: 1e-3, s: 1, m: 60, h: 3600 };
  const re = /([0-9]*\.?[0-9]+)(ns|us|µs|μs|ms|s|m|h)/g;
  let total = 0, matched = false, m: RegExpExecArray | null;
  while ((m = re.exec(s)) !== null) {
    const u = mult[m[2]];
    if (u === undefined) continue;
    total += parseFloat(m[1]) * u;
    matched = true;
  }
  return matched ? Math.round(total * 1000) / 1000 : null;
}

function trimDescription(desc: string | undefined, max = 500): string | undefined {
  if (!desc) return undefined;
  return desc.length > max ? desc.slice(0, max) + '…' : desc;
}

// ── ORL location / rule mapping ──────────────────────────────────────────────

const RESOLUTION_STATUSES = new Set<ResolutionStatus>(['unchanged', 'shifted', 'deleted', 'invalidated']);

function toResolutionStatus(s: string | undefined): ResolutionStatus | undefined {
  if (!s || !RESOLUTION_STATUSES.has(s as ResolutionStatus)) return undefined;
  return s as ResolutionStatus;
}

function mapLocation(loc: OrlLocation, fallbackId: string): IntegrationsLocation {
  return {
    id: loc.id?.trim() || fallbackId,
    filePath: loc.file_path,
    startLine: loc.start_line,
    ...(loc.end_line !== undefined ? { endLine: loc.end_line } : {}),
    startColumn: loc.start_column ?? 0,
    ...(loc.end_column !== undefined ? { endColumn: loc.end_column } : {}),
  };
}

function mapFindingLocation(row: OrlFindingLocationRow): IntegrationsOrlFindingLocation {
  const loc: IntegrationsOrlFindingLocation = { id: row.id };
  if (row.original_location) loc.originalLocation = mapLocation(row.original_location, row.id);
  if (row.resolved_location) loc.resolvedLocation = mapLocation(row.resolved_location, row.id);
  const status = toResolutionStatus(row.resolution_status);
  if (status) loc.resolutionStatus = status;
  // ORL emits resolution_status but not remediated; derive it when not explicit
  if (row.remediated !== undefined) {
    loc.remediated = row.remediated;
  } else if (row.resolution_status !== undefined) {
    loc.remediated = row.resolution_status === 'shifted' || row.resolution_status === 'deleted';
  }
  if (row.remediateable !== undefined) loc.remediateable = row.remediateable;
  if (row.message) loc.message = row.message;
  if (row.level) loc.level = row.level;
  return loc;
}

function mapRule(rule: OrlReportRule): IntegrationsOrlReportRule {
  const meta = rule.metadata;
  const findingLocations = (rule.finding_locations ?? []).map(mapFindingLocation);
  const findings = rule.findings ?? rule.finding_locations?.length ?? 0;

  // Derive files from finding_locations when rule.files is absent
  const files: Array<{ path: string }> = rule.files?.length
    ? rule.files
    : [...new Set(
        (rule.finding_locations ?? [])
          .map(fl => fl.original_location?.file_path)
          .filter((p): p is string => Boolean(p)),
      )].map(p => ({ path: p }));

  return {
    name: rule.name,
    findings,
    fixes: rule.fixes ?? 0,
    changes: rule.changes ?? 0,
    errors: rule.errors ?? [],
    files,
    metadata: {
      name: meta?.name?.trim() || rule.name,
      ...(meta?.description ? { description: meta.description } : {}),
      ...(meta?.annotations ? { annotations: meta.annotations } : {}),
      ...(meta?.classifications?.length ? { classifications: meta.classifications } : {}),
    },
    ...(findingLocations.length ? { findingLocations } : {}),
  };
}

// ── Report normalization ──────────────────────────────────────────────────────

function buildOrlReport(report: OrlReport): IntegrationsOrlReport {
  const spec = report.spec;
  const rules = spec.rules ?? [];

  const sumRules = (key: 'findings' | 'fixes' | 'changes'): number =>
    rules.reduce((n, r) => n + (r[key] ?? 0), 0);

  const findings = Math.max(spec.findings ?? 0, sumRules('findings'));
  const fixes = Math.max(spec.fixes ?? 0, sumRules('fixes'));
  const changes = Math.max(spec.changes ?? 0, sumRules('changes'));

  // Runtime extras that don't fit V2 schema top-level fields go into metadata.annotations.
  const annotations: Record<string, string> = { ...report.metadata.annotations };
  if (spec.rules_skipped !== undefined) annotations['rules_skipped'] = String(spec.rules_skipped);
  if (spec.resolved_location_count !== undefined) annotations['resolved_location_count'] = String(spec.resolved_location_count);
  if (spec.duration !== undefined) annotations['duration'] = String(spec.duration);
  const display = report.metadata.display_name?.trim();
  if (display) annotations['display_name'] = display;

  return {
    type: 'Report',
    version: 'v1',
    metadata: {
      name: report.metadata.name,
      ...(trimDescription(report.metadata.description) !== undefined
        ? { description: trimDescription(report.metadata.description) }
        : {}),
      ...(Object.keys(annotations).length > 0 ? { annotations } : {}),
    },
    workspace: spec.workspace ?? '.',
    language: spec.language ?? 'unknown',
    rules_applied: spec.rules_applied ?? rules.length,
    findings,
    fixes,
    changes,
    errors: spec.errors ?? [],
    rules: rules.map(mapRule),
  };
}

// ── Git diffs and file content ────────────────────────────────────────────────

function changedFilePaths(report: OrlReport): string[] {
  const files = new Set<string>();
  for (const key of Object.keys(report.spec.files_changed ?? {})) files.add(key);
  for (const rule of report.spec.rules ?? []) {
    for (const key of Object.keys(rule.files_changed ?? {})) files.add(key);
  }
  return [...files];
}

// Strip git-specific preamble lines (diff --git, index, mode) that most unified-diff
// parsers don't handle, leaving only the standard --- / +++ / @@ portion.
function stripGitPreamble(diff: string): string {
  return diff
    .split('\n')
    .filter(l =>
      !l.startsWith('diff --git ') &&
      !l.startsWith('index ') &&
      !l.startsWith('new file mode') &&
      !l.startsWith('deleted file mode') &&
      !l.startsWith('old mode') &&
      !l.startsWith('new mode'),
    )
    .join('\n')
    .trim();
}

function collectGitDiffs(workspace: string, files: string[]): Record<string, string> | undefined {
  const diffs: Record<string, string> = {};
  for (const file of files) {
    try {
      const raw = execFileSync('git', ['diff', 'HEAD', '--', file], {
        cwd: workspace, encoding: 'utf8', maxBuffer: 50 * 1024 * 1024,
      }).trim();
      if (raw) diffs[file] = Buffer.from(stripGitPreamble(raw)).toString('base64');
    } catch { /* git unavailable or no diff */ }
  }
  return Object.keys(diffs).length > 0 ? diffs : undefined;
}

function collectFileContent(workspace: string, files: string[]): Record<string, string> | undefined {
  const contents: Record<string, string> = {};
  for (const file of files) {
    try {
      const abs = path.resolve(workspace, file);
      if (fs.existsSync(abs) && fs.statSync(abs).isFile()) {
        contents[file] = Buffer.from(fs.readFileSync(abs, 'utf8')).toString('base64');
      }
    } catch { /* skip */ }
  }
  return Object.keys(contents).length > 0 ? contents : undefined;
}

// ── Scan identity (client-side dedup) ────────────────────────────────────────

function computeScanId(args: CliArgs, orlReport: IntegrationsOrlReport): string {
  const repoKey = args.repo
    ?? (args.workspace ? String(args.workspace).split('/').filter(Boolean).pop() : '')
    ?? 'workspace';
  const identity = [
    repoKey,
    args.branch ?? '',
    args['request-origin'] ?? 'CODE_AGENT',
    orlReport.language,
    orlReport.rules_applied,
    orlReport.findings,
    orlReport.fixes,
    orlReport.changes,
  ];
  return createHash('sha256').update(JSON.stringify(identity)).digest('hex');
}

// ── Build V2 request body ─────────────────────────────────────────────────────

function buildBody(
  args: CliArgs,
  report: OrlReport,
  orlReport: IntegrationsOrlReport,
  gitDiffs: Record<string, string> | undefined,
  remediatedFileContent: Record<string, string> | undefined,
): V2Body {
  const workflowStatus = {
    status: ((report.spec.errors?.length ?? 0) > 0 ? 'failure' : 'success') as 'success' | 'failure',
    errors: (report.spec.errors ?? []).map(e => typeof e === 'string' ? e : JSON.stringify(e)),
  };
  const completedAt = report.metadata.annotations?.['generated-at'];
  const timing = completedAt ? { completedAt } : undefined;

  const reportItem: V2Body['reports'][number] = {
    path: args.workspace ?? orlReport.workspace,
    branch: args.branch ?? '',
    ...(timing?.completedAt ? { timestamp: timing.completedAt } : {}),
    workflowStatus,
    ...(timing ? { timing } : {}),
    orlReport,
  };

  if (args.repo && args['pr-url'] && args['pr-id']) {
    const [ownerName = '', repositoryName = ''] = String(args.repo).split('/');
    reportItem.resultingPullRequest = {
      repositoryId: '',
      repositoryName,
      ownerId: '',
      ownerName,
      number: String(args['pr-id']),
      url: args['pr-url'],
      title: '',
      sourceBranch: args.branch ?? '',
      targetBranch: '',
      status: 'OPEN',
      provider: 'GitHub',
    };
  }

  const body: V2Body = {
    version: 2,
    requestOrigin: args['request-origin'] ?? 'CODE_AGENT',
    effect: args.effect ?? 'SubmitForReview',
    reports: [reportItem],
    errors: [],
    durationInSeconds: Math.round(Math.max(0, Number(args.duration) || 0)),
    workflowStatus,
    ...(timing ? { timing } : {}),
    ...(gitDiffs ? { gitDiffs } : {}),
    ...(remediatedFileContent ? { remediatedFileContent } : {}),
  };

  if (args.repo && args['pr-url'] && args['pr-id']) {
    const [ownerName = '', repositoryName = ''] = String(args.repo).split('/');
    body.scmContext = {
      scmType: 'GITHUB',
      resultingPullRequest: {
        repositoryId: '',
        repositoryName,
        ownerId: '',
        ownerName,
        number: String(args['pr-id']),
        url: args['pr-url'],
        title: '',
        sourceBranch: args.branch ?? '',
        targetBranch: '',
        status: 'OPEN',
        provider: 'GitHub',
      },
    };
  }

  return body;
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const args = parseArgs(process.argv.slice(2));
  if (!args.report) skip('no --report path given');

  const rawText = fs.readFileSync(args.report, 'utf8');
  const report = (rawText.trimStart().startsWith('{')
    ? JSON.parse(rawText)
    : yaml.parse(rawText)) as OrlReport;

  const workspace = args.workspace ?? report.spec.workspace ?? '.';
  const reportDur = parseGoDuration(report.spec.duration);
  if (reportDur !== null) args.duration = String(reportDur);

  const orlReport = buildOrlReport(report);
  const scanId = computeScanId(args, orlReport);

  const files = changedFilePaths(report);
  const gitDiffs = collectGitDiffs(workspace, files);
  const remediatedFileContent = collectFileContent(workspace, files);

  if (args['dry-run']) {
    console.log(JSON.stringify(buildBody(args, report, orlReport, gitDiffs, remediatedFileContent), null, 2));
    return;
  }

  if (!args.force && ledgerHas(scanId)) {
    console.log(`submit-orl-report: scan ${scanId.slice(0, 12)} already submitted — rejecting as duplicate (client-side; pass --force to override).`);
    process.exit(0);
  }

  const token = process.env.GOMBOC_PAT ?? process.env.GOMBOC_ACCESS_TOKEN ?? process.env.GOMBOC_API_TOKEN;
  if (!token) skip('GOMBOC_ACCESS_TOKEN / GOMBOC_API_TOKEN not set');

  const accountId = tenantIdFromToken(token);
  if (!accountId) skip('access token has no tenantId claim');

  const baseUrl = (process.env.INTEGRATIONS_SERVICE_URL ?? 'https://integrations.app.gomboc.ai').replace(/\/$/, '');
  const sdk = await initIntegrationsServiceSdk({ accessToken: token, accountId, baseUrl, logger: console });

  const body = buildBody(args, report, orlReport, gitDiffs, remediatedFileContent);
  const result = await sdk.createOrlReportEventV2(body);

  if (result.isOk()) {
    ledgerAdd(scanId);
    const d = result.value ?? {};
    console.log(
      `submit-orl-report: submitted scan ${scanId.slice(0, 12)} ` +
      `(${orlReport.findings} findings, ${orlReport.fixes} fixes) to ${baseUrl}` +
      ('jobId' in d && d.jobId ? ` [jobId=${d.jobId}]` : '') +
      ('message' in d && d.message ? ` — ${d.message}` : '') +
      ('success' in d && d.success === false ? ' [success=false]' : '')
    );
  } else {
    const err = result.error;
    const status = err.statusCode ?? '?';
    const dup = status === 409 || /duplicat/i.test(JSON.stringify(err));
    warn(
      `Integrations POST ${dup ? 'rejected as duplicate' : 'failed'} (${status}) for scan ` +
      `${scanId.slice(0, 12)}: ${JSON.stringify(err).slice(0, 300)} — non-blocking.`
    );
  }

  process.exit(0);
}

main();
