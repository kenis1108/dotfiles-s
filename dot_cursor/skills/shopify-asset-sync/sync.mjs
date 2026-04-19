#!/usr/bin/env node
// One-way Shopify Files migrator: source store → destination store.
// See ./SKILL.md and ./README.md for usage. Capability spec at
// openspec/specs/asset-sync-tool/ in any consumer repo.

import { readFile, writeFile, mkdir, readdir, stat as fsStat } from 'node:fs/promises';
import { existsSync, statSync, readFileSync } from 'node:fs';
import { dirname, resolve as pathResolve, join as pathJoin } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';

const SKILL_VERSION = '2026.04.19';
const SKILL_DIR = dirname(fileURLToPath(import.meta.url));
const API_VERSION = '2025-01';

// Node version guard — relies on parseArgs (18.3+), global fetch (18+), FormData/Blob (18+).
{
  const major = Number(process.versions.node.split('.')[0]);
  if (!Number.isFinite(major) || major < 18) {
    process.stderr.write(`shopify-asset-sync requires Node 18+. Got ${process.versions.node}\n`);
    process.exit(2);
  }
}

const EXIT_OK = 0;
const EXIT_UPLOAD_ISSUE = 1;
const EXIT_CONFIG = 2;

// Tuning (previously config.json) — kept as module-level constants since they
// are tool-intrinsic, not per-invocation. Override via code edit if needed.
const UPLOAD_BATCH_SIZE = 10;
const BATCH_SLEEP_MS = 250;
const POLL_TIMEOUT_MS = 90_000;
const POLL_INTERVAL_MS = 2_000;
const CONFIRM_SLEEP_MS = 5_000;

const REQUIRED_ENV = [
  'SHOPIFY_SRC_STORE',
  'SHOPIFY_SRC_CLIENT_ID',
  'SHOPIFY_SRC_CLIENT_SECRET',
  'SHOPIFY_DST_STORE',
  'SHOPIFY_DST_CLIENT_ID',
  'SHOPIFY_DST_CLIENT_SECRET',
];

const DEFAULT_ENV_PATH = pathJoin(SKILL_DIR, '.env');
const DEFAULT_LOG_DIR = pathJoin(SKILL_DIR, '.log');

const HELP = `
shopify-asset-sync v${SKILL_VERSION} — copy named Shopify Files from a source store to a destination store.

Usage:
  node ~/.cursor/skills/shopify-asset-sync/sync.mjs --scan <glob>[,<glob>]...        # dry-run
  node ~/.cursor/skills/shopify-asset-sync/sync.mjs --scan <glob> --apply            # upload missing to DST
  node ~/.cursor/skills/shopify-asset-sync/sync.mjs --scan <glob> --only <regex>     # filter filenames
  node ~/.cursor/skills/shopify-asset-sync/sync.mjs --scan <glob> --force <a,b>      # ghost-delete DST and re-upload
  node ~/.cursor/skills/shopify-asset-sync/sync.mjs --scan <glob> --manifest-out <path>
  node ~/.cursor/skills/shopify-asset-sync/sync.mjs --env <path>                     # override .env location
  node ~/.cursor/skills/shopify-asset-sync/sync.mjs --help

--scan is repeatable and/or comma-separated; globs are resolved against process.cwd().
  Supported patterns:  literal path, * (segment wildcard), ** (recursive), ? (single char).

Default paths:
  .env       : ${DEFAULT_ENV_PATH}
  manifests  : ${DEFAULT_LOG_DIR}/asset-sync-<ISO-ts>.{json,csv}

Env vars (in the active .env):
  SHOPIFY_SRC_STORE, SHOPIFY_SRC_CLIENT_ID, SHOPIFY_SRC_CLIENT_SECRET   # where to copy FROM
  SHOPIFY_DST_STORE, SHOPIFY_DST_CLIENT_ID, SHOPIFY_DST_CLIENT_SECRET   # where to copy TO

Credentials come from the Shopify Dev Dashboard (dev.shopify.com/dashboard) —
Settings → Client ID + Client secret for each app. The app and the store MUST
share a Dev Dashboard organisation, otherwise OAuth returns shop_not_permitted.
`.trim();

// ─── env loader ─────────────────────────────────────────────────────────────

function loadEnv(envPath) {
  if (!existsSync(envPath)) {
    die(
      EXIT_CONFIG,
      `Missing ${envPath}. Copy ${pathJoin(SKILL_DIR, '.env.example')} to this path and fill in tokens, or pass --env <path>.`,
    );
  }
  const raw = readFileSync(envPath, 'utf8');
  const out = {};
  for (const line of raw.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq < 0) continue;
    const key = trimmed.slice(0, eq).trim();
    let value = trimmed.slice(eq + 1).trim();
    if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
      value = value.slice(1, -1);
    }
    out[key] = value;
  }
  const missing = REQUIRED_ENV.filter((k) => !out[k] || out[k].includes('xxxxxx') || out[k].includes('your-'));
  if (missing.length) {
    die(EXIT_CONFIG, `Missing or placeholder values in ${envPath}: ${missing.join(', ')}`);
  }
  for (const storeKey of ['SHOPIFY_SRC_STORE', 'SHOPIFY_DST_STORE']) {
    // Accept "shopify-theme-a", "shopify-theme-a.myshopify.com", or "https://shopify-theme-a.myshopify.com".
    let v = out[storeKey].replace(/^https?:\/\//, '').replace(/\/+$/, '').trim();
    if (!v.endsWith('.myshopify.com')) v = `${v}.myshopify.com`;
    out[storeKey] = v;
  }
  return out;
}

// ─── glob expansion (vendored minimal walker) ───────────────────────────────
// Supports: literal segments, ? (one non-/ char), * (segment wildcard), ** (any depth).
// Resolved against the caller-supplied `cwd` (= process.cwd()), not SKILL_DIR.

function globSegmentToRegex(seg) {
  let re = '^';
  for (const c of seg) {
    if (c === '*') re += '[^/]*';
    else if (c === '?') re += '[^/]';
    else re += c.replace(/[.+^${}()|[\]\\]/g, '\\$&');
  }
  re += '$';
  return new RegExp(re);
}

async function expandScanGlob(pattern, cwd) {
  // Short-circuit: literal path, no glob metacharacters.
  if (!/[*?[]/.test(pattern)) {
    const abs = pathResolve(cwd, pattern);
    return existsSync(abs) && statSync(abs).isFile() ? [abs] : [];
  }
  const parts = pattern.split('/').filter((p) => p !== '');
  async function walk(baseAbs, i) {
    if (i === parts.length) {
      try {
        const st = await fsStat(baseAbs);
        return st.isFile() ? [baseAbs] : [];
      } catch {
        return [];
      }
    }
    let entries;
    try {
      entries = await readdir(baseAbs, { withFileTypes: true });
    } catch {
      return [];
    }
    const part = parts[i];
    if (part === '**') {
      const out = [];
      // '**' matches zero segments: advance i without descending.
      out.push(...(await walk(baseAbs, i + 1)));
      for (const e of entries) {
        if (e.isDirectory()) {
          out.push(...(await walk(pathResolve(baseAbs, e.name), i))); // stay on '**'
        }
      }
      return out;
    }
    if (/[*?[]/.test(part)) {
      const re = globSegmentToRegex(part);
      const matches = entries.filter((e) => re.test(e.name));
      const out = [];
      for (const e of matches) {
        out.push(...(await walk(pathResolve(baseAbs, e.name), i + 1)));
      }
      return out;
    }
    const next = pathResolve(baseAbs, part);
    if (!existsSync(next)) return [];
    return walk(next, i + 1);
  }
  return walk(cwd, 0);
}

async function resolveScanTargets(scanArgs, cwd) {
  // `scanArgs` is the array of --scan values (parseArgs returns an array when
  // multiple:true). Each value may itself be comma-separated for convenience.
  const patterns = [];
  for (const arg of scanArgs) {
    for (const part of arg.split(',')) {
      const p = part.trim();
      if (p) patterns.push(p);
    }
  }
  if (!patterns.length) {
    die(EXIT_CONFIG, `--scan is required. Pass one or more globs (repeatable or comma-separated).`);
  }
  const resolved = new Map(); // abs → { rel, abs }
  const unmatched = [];
  for (const pattern of patterns) {
    const matches = await expandScanGlob(pattern, cwd);
    if (!matches.length) {
      unmatched.push(pattern);
      continue;
    }
    for (const abs of matches) {
      if (!resolved.has(abs)) {
        const rel = abs.startsWith(cwd + '/') ? abs.slice(cwd.length + 1) : abs;
        resolved.set(abs, { rel, abs });
      }
    }
  }
  if (!resolved.size) {
    die(EXIT_CONFIG, `--scan matched zero files under ${cwd}. Patterns: ${unmatched.join(', ')}`);
  }
  if (unmatched.length) {
    console.warn(`WARN: --scan patterns matched nothing and were skipped: ${unmatched.join(', ')}`);
  }
  return Array.from(resolved.values()).sort((a, b) => a.rel.localeCompare(b.rel));
}

// ─── discovery ──────────────────────────────────────────────────────────────

// JSON allows the solidus `/` to be escaped as `\/` (spec §9). Shopify's theme
// editor sometimes writes `"shopify:\/\/shop_images\/foo.png"` and sometimes
// `"shopify://shop_images/foo.png"` — we must accept both, otherwise half the
// assets in escaped templates silently go unnoticed.
// `SEP` matches either `/` or `\/`; filename char class stops at `"` or
// whitespace and may include `\` so that escaped sub-paths under
// `shopify://files/...` survive; we unescape with `unescapeSolidus()` below.
const SEP = '(?:\\\\\\/|\\/)';
const SHOP_IMAGES_RE = new RegExp(`shopify:${SEP}{2}shop_images${SEP}([^"\\s]+)`, 'g');
const FILES_RE = new RegExp(`shopify:${SEP}{2}files${SEP}([^"\\s]+)`, 'g');

function unescapeSolidus(s) {
  return s.replace(/\\\//g, '/');
}

async function discoverAssets(scanTargets) {
  const assets = new Map();
  for (const { rel, abs } of scanTargets) {
    const text = await readFile(abs, 'utf8');
    for (const re of [SHOP_IMAGES_RE, FILES_RE]) {
      re.lastIndex = 0;
      let m;
      while ((m = re.exec(text)) !== null) {
        const raw = unescapeSolidus(m[1]);
        // Shopify Files is flat — `shopify://files/<sub>/<basename>` (e.g.
        // `shopify://files/videos/foo.mp4`) resolves by basename. We key on the
        // basename so the Admin `filename:` query and `fileCreate.alt` match.
        const filename = raw.includes('/') ? raw.split('/').pop() : raw;
        const existing = assets.get(filename) || { filename, scheme: re === SHOP_IMAGES_RE ? 'shop_images' : 'files', sources: [] };
        if (!existing.sources.includes(rel)) existing.sources.push(rel);
        assets.set(filename, existing);
      }
    }
  }
  return Array.from(assets.values()).sort((a, b) => a.filename.localeCompare(b.filename));
}

// ─── OAuth client-credentials + token cache ─────────────────────────────────

// Per-store token cache: { [store]: { token, expiresAt } }
const TOKEN_CACHE = new Map();
const TOKEN_REFRESH_LEAD_MS = 60_000;

async function getAccessToken(store, clientId, clientSecret) {
  const cached = TOKEN_CACHE.get(store);
  if (cached && Date.now() < cached.expiresAt - TOKEN_REFRESH_LEAD_MS) {
    return cached.token;
  }
  const url = `https://${store}/admin/oauth/access_token`;
  const body = new URLSearchParams({
    grant_type: 'client_credentials',
    client_id: clientId,
    client_secret: clientSecret,
  });
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  const text = await response.text();
  let payload;
  try { payload = JSON.parse(text); } catch { payload = { raw: text }; }
  if (!response.ok) {
    if (payload?.error === 'shop_not_permitted' || /shop_not_permitted/.test(text)) {
      die(
        EXIT_CONFIG,
        `shop_not_permitted on ${store}. The app and the store must be in the same Dev Dashboard organisation — see SKILL.md "Troubleshooting".`,
      );
    }
    die(
      EXIT_CONFIG,
      `OAuth token exchange failed on ${store}: HTTP ${response.status} ${text.slice(0, 300)}\n` +
      `Verify SHOPIFY_*_CLIENT_ID / SHOPIFY_*_CLIENT_SECRET in the active .env (copied from Dev Dashboard → Settings).`,
    );
  }
  if (!payload.access_token) {
    die(EXIT_CONFIG, `OAuth response from ${store} missing access_token: ${text.slice(0, 300)}`);
  }
  const expiresAt = Date.now() + (payload.expires_in || 86400) * 1000;
  TOKEN_CACHE.set(store, { token: payload.access_token, expiresAt });
  return payload.access_token;
}

// Helper: per-role credential bundle from the loaded env map.
function credsFor(env, role /* 'SRC' | 'DST' */) {
  return {
    store: env[`SHOPIFY_${role}_STORE`],
    clientId: env[`SHOPIFY_${role}_CLIENT_ID`],
    clientSecret: env[`SHOPIFY_${role}_CLIENT_SECRET`],
  };
}

// ─── GraphQL client ─────────────────────────────────────────────────────────

async function graphql(creds, query, variables = {}) {
  const { store, clientId, clientSecret } = creds;
  const token = await getAccessToken(store, clientId, clientSecret);
  const url = `https://${store}/admin/api/${API_VERSION}/graphql.json`;
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Shopify-Access-Token': token,
    },
    body: JSON.stringify({ query, variables }),
  });
  if (!response.ok) {
    const body = await response.text();
    // A 401 mid-run usually means the cached token was revoked or scopes changed — drop cache and bubble up.
    if (response.status === 401) TOKEN_CACHE.delete(store);
    throw new Error(`HTTP ${response.status} from ${store}: ${body.slice(0, 500)}`);
  }
  const payload = await response.json();
  if (payload.errors?.length) {
    throw new Error(`GraphQL errors from ${store}: ${JSON.stringify(payload.errors)}`);
  }
  return payload;
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function graphqlWithRetry(creds, query, variables = {}) {
  const backoffs = [1000, 2000, 4000, 8000, 16000];
  for (let attempt = 0; attempt <= backoffs.length; attempt++) {
    try {
      const payload = await graphql(creds, query, variables);
      const throttled = payload.extensions?.cost?.throttleStatus;
      if (throttled) {
        const need = payload.extensions.cost.requestedQueryCost || 10;
        if (throttled.currentlyAvailable < need && attempt < backoffs.length) {
          await sleep(backoffs[attempt]);
          continue;
        }
      }
      return payload;
    } catch (err) {
      const msg = String(err.message || err);
      const throttled = msg.includes('THROTTLED') || msg.includes('429');
      if (throttled && attempt < backoffs.length) {
        await sleep(backoffs[attempt]);
        continue;
      }
      throw err;
    }
  }
  throw new Error(`graphqlWithRetry: retries exhausted on ${creds.store}`);
}

// ─── file lookup ────────────────────────────────────────────────────────────

const FIND_FILE_QUERY = `
  query FindFileByName($q: String!) {
    files(first: 5, query: $q) {
      nodes {
        id
        fileStatus
        updatedAt
        ... on MediaImage {
          alt
          image { url }
          originalSource { url }
          preview { image { url } }
        }
        ... on GenericFile {
          alt
          url
          originalFileSize
          preview { image { url } }
        }
        ... on Video {
          alt
          sources { url format mimeType }
          originalSource { url }
          preview { image { url } }
        }
      }
    }
  }
`;

function extractUrl(node) {
  return (
    node?.image?.url ||
    node?.originalSource?.url ||
    node?.url ||
    node?.sources?.[0]?.url ||
    node?.preview?.image?.url ||
    null
  );
}

function inferContentType(node, filename) {
  if (node?.__typename === 'Video' || /\.(mp4|mov|webm|m4v)$/i.test(filename)) return 'VIDEO';
  if (/\.(jpe?g|png|gif|webp|svg|avif|heic)$/i.test(filename)) return 'IMAGE';
  return 'FILE';
}

async function findFileByName(creds, filename) {
  const payload = await graphqlWithRetry(creds, FIND_FILE_QUERY, {
    q: `filename:${filename}`,
  });
  const nodes = payload.data?.files?.nodes || [];
  const exact = nodes.find(
    (n) =>
      n.alt === filename ||
      (extractUrl(n) || '').includes(`/${encodeURIComponent(filename)}`) ||
      (extractUrl(n) || '').includes(`/${filename}`),
  );
  const picked = exact || nodes[0];
  if (!picked) return { matches: [] };
  const url = extractUrl(picked);
  return {
    id: picked.id,
    url,
    updatedAt: picked.updatedAt,
    fileStatus: picked.fileStatus,
    matches: nodes.map((n) => ({ id: n.id, url: extractUrl(n), updatedAt: n.updatedAt })),
  };
}

// ─── force-delete (ghost cleanup) ──────────────────────────────────────────
// Shopify Files can go "ghost": the MediaImage/GenericFile node still resolves
// via `files(query: "filename:...")` with an id + alt, but the underlying CDN
// object is 404. Templates referencing `shopify://shop_images/<name>` then fail
// to render (Liquid `image_tag` silently drops the wrapper). We cannot detect
// this by `fileStatus` alone (ghosts stay READY). `--force <names>` lets the
// operator blow away every DST file with that alt so the normal upload path
// re-creates a fresh file.
const FILE_DELETE_MUTATION = `
  mutation FileDelete($fileIds: [ID!]!) {
    fileDelete(fileIds: $fileIds) {
      deletedFileIds
      userErrors { field message code }
    }
  }
`;

async function fileDeleteAllByName(creds, filename) {
  const deleted = [];
  // Loop because findFileByName only returns first 5; keep deleting until the
  // query returns no ids (handles stores with many same-named entries).
  for (let guard = 0; guard < 10; guard++) {
    const dst = await findFileByName(creds, filename);
    if (!dst.id) break;
    const ids = dst.matches.map((m) => m.id).filter(Boolean);
    if (!ids.length) break;
    const payload = await graphqlWithRetry(creds, FILE_DELETE_MUTATION, { fileIds: ids });
    const errors = payload.data?.fileDelete?.userErrors || [];
    if (errors.length) throw new Error(`fileDelete(${filename}) errors: ${JSON.stringify(errors)}`);
    deleted.push(...(payload.data?.fileDelete?.deletedFileIds || []));
  }
  return deleted;
}

// ─── upload ─────────────────────────────────────────────────────────────────

const FILE_CREATE_MUTATION = `
  mutation FileCreate($files: [FileCreateInput!]!) {
    fileCreate(files: $files) {
      files { id fileStatus alt createdAt }
      userErrors { field message code }
    }
  }
`;

// Videos cannot be created by handing Shopify a foreign-store CDN URL — the
// Admin API rejects them as `Invalid video url=...`. They must instead flow
// through a staged upload: stagedUploadsCreate → S3 POST → fileCreate.
const STAGED_UPLOADS_MUTATION = `
  mutation StagedUploads($input: [StagedUploadInput!]!) {
    stagedUploadsCreate(input: $input) {
      stagedTargets {
        url
        resourceUrl
        parameters { name value }
      }
      userErrors { field message }
    }
  }
`;

function mimeTypeFor(filename) {
  const ext = filename.toLowerCase().split('.').pop();
  return ({
    mp4: 'video/mp4', mov: 'video/quicktime', webm: 'video/webm', m4v: 'video/x-m4v',
    jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png', gif: 'image/gif',
    webp: 'image/webp', svg: 'image/svg+xml', avif: 'image/avif',
  })[ext] || 'application/octet-stream';
}

// Download bytes and stage a single video to DST's S3 bucket, returning the
// resourceUrl suitable for fileCreate(originalSource:). Stays in-memory; fine
// for the videos this tool handles (≤ a few hundred MB each).
async function stagedUploadVideo(creds, { filename, sourceUrl }) {
  const src = await fetch(sourceUrl);
  if (!src.ok) throw new Error(`download failed ${src.status} for ${sourceUrl}`);
  const bytes = Buffer.from(await src.arrayBuffer());
  const mimeType = mimeTypeFor(filename);

  const payload = await graphqlWithRetry(creds, STAGED_UPLOADS_MUTATION, {
    input: [{
      resource: 'VIDEO',
      filename,
      mimeType,
      httpMethod: 'POST',
      fileSize: String(bytes.length),
    }],
  });
  const errs = payload.data?.stagedUploadsCreate?.userErrors || [];
  if (errs.length) throw new Error(`stagedUploadsCreate: ${JSON.stringify(errs)}`);
  const target = payload.data?.stagedUploadsCreate?.stagedTargets?.[0];
  if (!target) throw new Error('stagedUploadsCreate returned no targets');

  const form = new FormData();
  for (const { name, value } of target.parameters) form.append(name, value);
  form.append('file', new Blob([bytes], { type: mimeType }), filename);
  const resp = await fetch(target.url, { method: 'POST', body: form });
  if (!resp.ok) {
    const body = await resp.text();
    throw new Error(`staged S3 POST failed ${resp.status}: ${body.slice(0, 300)}`);
  }
  return target.resourceUrl;
}

async function fileCreateBatch(creds, pairs) {
  // Split by content type: non-videos can go through the bulk mutation with
  // `originalSource` = SRC CDN URL; videos need a staged upload first.
  const videoPairs = [];
  const directPairs = [];
  for (const p of pairs) {
    if (inferContentType(null, p.filename) === 'VIDEO') videoPairs.push(p);
    else directPairs.push(p);
  }

  const stagedFiles = [];
  const stageErrors = [];
  for (const p of videoPairs) {
    try {
      const resourceUrl = await stagedUploadVideo(creds, { filename: p.filename, sourceUrl: p.url });
      stagedFiles.push({ alt: p.filename, contentType: 'VIDEO', originalSource: resourceUrl });
    } catch (err) {
      stageErrors.push({
        field: ['files', '-', 'originalSource'],
        code: 'STAGED_UPLOAD_FAILED',
        message: `${p.filename}: ${String(err.message || err).slice(0, 400)}`,
      });
    }
  }

  // Always pin `filename` so Shopify stores the file under the exact name our
  // Liquid templates reference (shopify://shop_images/<filename>). Without this,
  // Shopify derives the stored filename from originalSource's path — and SRC
  // historically has files whose `alt` says "EB.jpg" while the actual URL is
  // `D8DDD667-…-EB4213C644E4.jpg`. That mismatch makes `/cdn/shop/files/EB.jpg`
  // 404 on DST even after a successful fileCreate.
  const directFiles = directPairs.map(({ filename, url }) => ({
    alt: filename,
    filename,
    contentType: inferContentType(null, filename),
    originalSource: url,
  }));

  const files = [...directFiles, ...stagedFiles];
  if (!files.length) return { created: [], errors: stageErrors };
  const payload = await graphqlWithRetry(creds, FILE_CREATE_MUTATION, { files });
  const errors = [...stageErrors, ...(payload.data?.fileCreate?.userErrors || [])];
  const created = payload.data?.fileCreate?.files || [];
  return { created, errors };
}

const NODE_STATUS_QUERY = `
  query NodeStatus($ids: [ID!]!) {
    nodes(ids: $ids) {
      ... on File {
        id
        fileStatus
        fileErrors { code details message }
      }
    }
  }
`;

async function pollUntilReady(creds, ids, { timeoutMs, intervalMs }) {
  const started = Date.now();
  const pending = new Set(ids);
  const results = new Map();
  while (pending.size > 0) {
    const elapsed = Date.now() - started;
    if (elapsed > timeoutMs) {
      for (const id of pending) results.set(id, { fileStatus: 'TIMEOUT', elapsedMs: elapsed });
      break;
    }
    const payload = await graphqlWithRetry(creds, NODE_STATUS_QUERY, {
      ids: Array.from(pending),
    });
    const nodes = payload.data?.nodes || [];
    for (const n of nodes) {
      if (!n) continue;
      if (n.fileStatus === 'READY' || n.fileStatus === 'FAILED') {
        results.set(n.id, {
          fileStatus: n.fileStatus,
          elapsedMs: Date.now() - started,
          fileErrors: n.fileErrors || [],
        });
        pending.delete(n.id);
      }
    }
    if (pending.size > 0) await sleep(intervalMs);
  }
  return results;
}

// ─── manifest ───────────────────────────────────────────────────────────────

async function writeManifest(rows, outPathBase) {
  const dir = dirname(outPathBase);
  await mkdir(dir, { recursive: true });
  const jsonPath = `${outPathBase}.json`;
  const csvPath = `${outPathBase}.csv`;
  await writeFile(
    jsonPath,
    JSON.stringify({ generatedAt: new Date().toISOString(), skillVersion: SKILL_VERSION, rows }, null, 2),
  );

  const headers = [
    'filename', 'sources', 'dstStatus', 'dstId', 'dstUpdatedAt',
    'srcStatus', 'srcUrl', 'uploadStatus', 'uploadId', 'elapsedMs', 'error',
  ];
  const csvLines = [headers.join(',')];
  for (const r of rows) {
    const cells = headers.map((h) => csvCell(r[h]));
    csvLines.push(cells.join(','));
  }
  await writeFile(csvPath, csvLines.join('\n') + '\n');
  return { jsonPath, csvPath };
}

function csvCell(v) {
  if (v === undefined || v === null) return '';
  const s = Array.isArray(v) ? v.join('; ') : String(v);
  if (/[",\n]/.test(s)) return `"${s.replace(/"/g, '""')}"`;
  return s;
}

// ─── main ───────────────────────────────────────────────────────────────────

function die(code, msg) {
  process.stderr.write(`ERROR: ${msg}\n`);
  process.exit(code);
}

function fmtSummary(rows) {
  const tally = {};
  for (const r of rows) {
    const k = r.__summaryBucket;
    tally[k] = (tally[k] || 0) + 1;
  }
  const order = [
    'already-in-dst', 'already-in-dst-ambiguous', 'copied',
    'missing-in-src', 'failed', 'timeout', 'skipped-by-filter',
  ];
  const lines = [];
  for (const k of order) {
    if (tally[k] != null) lines.push(`  ${k.padEnd(26)} ${tally[k]}`);
  }
  for (const [k, v] of Object.entries(tally)) {
    if (!order.includes(k)) lines.push(`  ${k.padEnd(26)} ${v}`);
  }
  return lines.join('\n');
}

async function main() {
  const { values } = parseArgs({
    options: {
      apply: { type: 'boolean', default: false },
      scan: { type: 'string', multiple: true },
      only: { type: 'string' },
      force: { type: 'string' },
      env: { type: 'string' },
      'manifest-out': { type: 'string' },
      help: { type: 'boolean', default: false },
    },
    allowPositionals: false,
  });

  if (values.help) {
    console.log(HELP);
    process.exit(EXIT_OK);
  }

  const envPath = values.env ? pathResolve(process.cwd(), values.env) : DEFAULT_ENV_PATH;
  const env = loadEnv(envPath);

  const cwd = process.cwd();
  const scanArgs = values.scan || [];
  const scanTargets = await resolveScanTargets(scanArgs, cwd);

  const srcCreds = credsFor(env, 'SRC');
  const dstCreds = credsFor(env, 'DST');
  const assets = await discoverAssets(scanTargets);

  const filter = values.only ? new RegExp(values.only) : null;
  const forceSet = new Set(
    (values.force || '')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean),
  );
  const scopedAssets = filter ? assets.filter((a) => filter.test(a.filename)) : assets;
  const filteredOut = assets.length - scopedAssets.length;

  console.log(`shopify-asset-sync v${SKILL_VERSION}`);
  console.log(`cwd=${cwd}`);
  console.log(`.env=${envPath}`);
  console.log(`SRC=${srcCreds.store}  DST=${dstCreds.store}`);
  console.log(`Scanned ${scanTargets.length} file(s); discovered ${assets.length} unique asset filename(s).`);
  if (filteredOut) console.log(`  (${filteredOut} filtered out by --only "${values.only}")`);
  if (forceSet.size) console.log(`  (${forceSet.size} filename(s) marked for force-redownload: ${[...forceSet].join(', ')})`);

  const rows = [];

  console.log(`\nChecking DST store (${dstCreds.store}) for existing files ...`);
  for (const asset of scopedAssets) {
    const dst = await findFileByName(dstCreds, asset.filename);
    const row = {
      filename: asset.filename,
      sources: asset.sources,
      scheme: asset.scheme,
    };
    const forceThis = forceSet.has(asset.filename);
    if (forceThis && dst.id) {
      // Delete every DST file with this alt so the SRC-lookup + fileCreate path
      // can recreate a fresh, non-ghost record under the same filename.
      if (values.apply) {
        console.log(`  force: deleting ${dst.matches.length} DST file(s) named ${asset.filename} ...`);
        const deletedIds = await fileDeleteAllByName(dstCreds, asset.filename);
        row.dstForceDeletedIds = deletedIds;
        console.log(`  force: deleted ${deletedIds.length} id(s) for ${asset.filename}`);
      } else {
        console.log(`  force: would delete ${dst.matches.length} DST file(s) named ${asset.filename} (dry-run — pass --apply)`);
        row.dstForceDeletePlanned = dst.matches.map((m) => m.id);
      }
      row.dstStatus = 'missing-in-dst';
      row.dstForced = true;
      row.__summaryBucket = 'pending-src-lookup';
    } else if (dst.id) {
      row.dstStatus = dst.matches.length > 1 ? 'already-in-dst-ambiguous' : 'already-in-dst';
      row.dstId = dst.id;
      row.dstUpdatedAt = dst.updatedAt;
      row.__summaryBucket = row.dstStatus;
    } else {
      row.dstStatus = 'missing-in-dst';
      row.__summaryBucket = 'pending-src-lookup';
    }
    rows.push(row);
  }

  const needsSrcLookup = rows.filter((r) => r.dstStatus === 'missing-in-dst');
  if (needsSrcLookup.length) {
    console.log(`\nResolving ${needsSrcLookup.length} missing filename(s) on SRC store (${srcCreds.store}) ...`);
    for (const row of needsSrcLookup) {
      const src = await findFileByName(srcCreds, row.filename);
      if (src.id && src.url) {
        row.srcStatus = 'resolved';
        row.srcUrl = src.url;
        row.__summaryBucket = 'missing-in-dst-resolved';
      } else {
        row.srcStatus = 'missing-in-src';
        row.__summaryBucket = 'missing-in-src';
      }
    }
  }

  const resolvable = rows.filter((r) => r.__summaryBucket === 'missing-in-dst-resolved');

  console.log(`\nPre-upload summary:`);
  console.log(fmtSummary(rows));
  if (!resolvable.length) {
    console.log(`\nNothing to upload. ${values.apply ? '(--apply had no effect)' : '(dry-run clean)'}`);
  }

  if (values.apply && resolvable.length) {
    console.log(`\nAbout to upload ${resolvable.length} file(s) to ${dstCreds.store}.`);
    console.log(`Waiting ${CONFIRM_SLEEP_MS} ms — press Ctrl+C to abort.`);
    await sleep(CONFIRM_SLEEP_MS);

    for (let i = 0; i < resolvable.length; i += UPLOAD_BATCH_SIZE) {
      const batch = resolvable.slice(i, i + UPLOAD_BATCH_SIZE);
      console.log(`\nUploading batch ${Math.floor(i / UPLOAD_BATCH_SIZE) + 1} (${batch.length} file(s)) ...`);
      const { created, errors } = await fileCreateBatch(
        dstCreds,
        batch.map((r) => ({ filename: r.filename, url: r.srcUrl })),
      );
      if (errors.length) {
        console.error(`  userErrors:`, JSON.stringify(errors));
        for (const row of batch) {
          if (!row.uploadId) {
            row.uploadStatus = 'failed';
            row.__summaryBucket = 'failed';
            row.error = JSON.stringify(errors);
          }
        }
      }
      for (let j = 0; j < batch.length; j++) {
        const row = batch[j];
        const createdEntry = created[j];
        if (createdEntry) {
          row.uploadId = createdEntry.id;
        }
      }

      const ids = created.map((f) => f.id).filter(Boolean);
      if (ids.length) {
        const results = await pollUntilReady(dstCreds, ids, {
          timeoutMs: POLL_TIMEOUT_MS,
          intervalMs: POLL_INTERVAL_MS,
        });
        for (const row of batch) {
          if (!row.uploadId) continue;
          const res = results.get(row.uploadId);
          if (!res) continue;
          row.elapsedMs = res.elapsedMs;
          if (res.fileStatus === 'READY') {
            row.uploadStatus = 'copied';
            row.__summaryBucket = 'copied';
          } else if (res.fileStatus === 'TIMEOUT') {
            row.uploadStatus = 'timeout';
            row.__summaryBucket = 'timeout';
          } else {
            row.uploadStatus = 'failed';
            row.__summaryBucket = 'failed';
            row.error = JSON.stringify(res.fileErrors || res.fileStatus);
          }
        }
      }

      if (i + UPLOAD_BATCH_SIZE < resolvable.length) await sleep(BATCH_SLEEP_MS);
    }
  }

  const ts = new Date().toISOString().replace(/[:.]/g, '-');
  const manifestBase = values['manifest-out']
    ? pathResolve(process.cwd(), values['manifest-out'], `asset-sync-${ts}`)
    : pathJoin(DEFAULT_LOG_DIR, `asset-sync-${ts}`);
  const { jsonPath, csvPath } = await writeManifest(rows, manifestBase);

  console.log(`\nFinal summary:`);
  console.log(fmtSummary(rows));
  console.log(`\nManifest:`);
  console.log(`  ${jsonPath}`);
  console.log(`  ${csvPath}`);

  const anyFailed = rows.some((r) => ['failed', 'timeout'].includes(r.__summaryBucket));
  if (anyFailed) process.exit(EXIT_UPLOAD_ISSUE);
  if (!values.apply && resolvable.length > 0) {
    console.log(`\nDRY RUN — pass --apply to upload ${resolvable.length} file(s) to DST.`);
  }
  process.exit(EXIT_OK);
}

main().catch((err) => {
  console.error(err);
  process.exit(EXIT_UPLOAD_ISSUE);
});
