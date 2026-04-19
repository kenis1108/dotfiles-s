---
name: shopify-asset-sync
description: >-
  Copies Shopify Files (images + videos) from one source store to one destination
  store, keyed by filename. Use when the user wants to migrate, sync, or mirror
  assets between Shopify storefronts (NA↔PH, PH↔UK, shopify-theme-b↔regional, etc),
  recover "ghost" Shopify files whose CDN URL is 404 while the MediaImage record
  still exists, or attach a migration manifest to a Shopify theme PR. Triggers on
  phrases: shopify-asset-sync, sync Shopify files, copy/migrate/mirror assets
  between Shopify stores, Shopify file ghost recovery, fileCreate originalSource,
  stagedUploadsCreate VIDEO, shopify:// shop_images or files references, "images
  not displaying on PDP after migration".
---

# shopify-asset-sync

Node CLI that copies `shopify://shop_images/<name>` and `shopify://files/<name>` references from a source Shopify store into a destination Shopify store, preserving exact filenames so Liquid templates keep working without edits. Handles images via direct `fileCreate(originalSource:)`, videos via `stagedUploadsCreate → S3 POST → fileCreate`, and ghost-file recovery via `--force`.

This skill lives at `~/.cursor/skills/shopify-asset-sync/`. Invoke from **any repo's root** — scan globs are always resolved against `process.cwd()`.

## First-time setup

1. Create a Shopify Dev Dashboard app per store at <https://dev.shopify.com/dashboard/>. The app and the store MUST be in the same organisation — otherwise OAuth returns `shop_not_permitted`.
2. Install each app on its store (Dev stores tab → Install). Required Admin API scopes:
   - **Source** (read-only): `read_files`
   - **Destination** (read-write): `read_files`, `write_files`
3. `cp ~/.cursor/skills/shopify-asset-sync/.env.example ~/.cursor/skills/shopify-asset-sync/.env`
4. Fill in the six variables — **SRC** = where to copy FROM, **DST** = where to copy TO:
   ```
   SHOPIFY_SRC_STORE=shopify-theme-b.myshopify.com
   SHOPIFY_SRC_CLIENT_ID=...
   SHOPIFY_SRC_CLIENT_SECRET=...
   SHOPIFY_DST_STORE=shopify-theme-a.myshopify.com
   SHOPIFY_DST_CLIENT_ID=...
   SHOPIFY_DST_CLIENT_SECRET=...
   ```
5. `chmod 600 ~/.cursor/skills/shopify-asset-sync/.env`

When you switch direction (say, PH→UK), edit the same `.env` and swap which creds are in SRC vs DST. Or keep multiple env files and pass `--env <path>`.

## CLI reference

```
node ~/.cursor/skills/shopify-asset-sync/sync.mjs \
  --scan <glob>[,<glob>]...    (repeatable; required)
  [--apply]                    (default is dry-run)
  [--only <regex>]             (filter discovered filenames)
  [--force <name,name,...>]    (ghost cleanup — delete DST + re-upload)
  [--env <path>]               (default: ~/.cursor/skills/shopify-asset-sync/.env)
  [--manifest-out <dir>]       (default: ~/.cursor/skills/shopify-asset-sync/.log/)
  [--help]
```

### `--scan` glob syntax

Resolved against `process.cwd()`. Supports:

- literal paths: `templates/product.125w.json`
- segment wildcard: `templates/product.*.json`
- recursive wildcard: `sections/**/*.liquid`
- single-char: `templates/product.d?-eb.json`
- multiple globs: `--scan 'templates/product.*.json' --scan 'sections/pdp-hotspot-section.liquid'`
- or comma-joined: `--scan 'templates/product.*.json,sections/**/*.liquid'`

If **every** glob matches zero files, the tool exits with code 2 before any network call.

### Exit codes

- `0` — clean run (dry-run with no pending work, or `--apply` with every upload `READY`)
- `1` — at least one upload `failed` / `timeout`, or the manifest recorded any `missing-in-src`
- `2` — config error (missing env var, unmatched `--scan`, `shop_not_permitted`, missing `--env` path, …)

## Cookbook

### shopify NA → PH (historical — 5 templates for 2026/4/22 launch)

```bash
cd ~/Documents/repo/shopify-theme-a
# Dry-run against all 5 migrated PH templates + section deps
node ~/.cursor/skills/shopify-asset-sync/sync.mjs --scan \
  'templates/product.125w.json,templates/product.delta-pro-extra-battery.json,templates/product.delta-2-extra-battery.json,templates/product.d3-eb.json,templates/product.dp3-eb.json,sections/collection-text-section.liquid,sections/pdp-hotspot-section.liquid,sections/pdp-tooltips-section.liquid,sections/text.liquid'

# When the dry-run manifest looks right, commit the upload:
node ~/.cursor/skills/shopify-asset-sync/sync.mjs --scan '<same list>' --apply
```

### Single-template migration

```bash
cd <any regional shopify repo>
node ~/.cursor/skills/shopify-asset-sync/sync.mjs --scan 'templates/product.125w.json' --apply
```

### Ghost-file recovery

Symptom: a PDP preview is missing desktop images; `curl -I <cdn-url>` returns 404 even though Shopify's Files admin shows the record with `fileStatus: READY`. The record is a "ghost" — the admin row exists, the CDN object is gone.

```bash
# Delete every DST record with alt "EB.jpg" or "LFP_compression.jpg", then re-upload from SRC:
node ~/.cursor/skills/shopify-asset-sync/sync.mjs \
  --scan 'templates/product.d3-eb.json' \
  --apply --force 'EB.jpg,LFP_compression.jpg'
```

The `--force` pass loops `findFileByName` up to 10 times per name to clear all matching ghosts (Shopify returns only first 5 per page). `fileCreate` is then called with an **explicit `filename` field**, so the new record is stored under the exact name regardless of what SRC's internal filename was.

### PR-friendly manifest

```bash
node ~/.cursor/skills/shopify-asset-sync/sync.mjs \
  --scan 'templates/product.125w.json' \
  --manifest-out /tmp/pr-123/
# writes /tmp/pr-123/asset-sync-<ts>.json + .csv, skips the global .log/
```

Attach the JSON file to the PR description; reviewers see every filename's DST lookup, SRC lookup, and upload outcome.

## How it works (one-liner per phase)

1. **Discover** — regex-scan the `--scan` files for `shopify://shop_images/<name>` and `shopify://files/<name>` (both unescaped and JSON-escaped `\/`), dedup by basename.
2. **Auth** — lazy OAuth `client_credentials` per store; access tokens cached in-memory for the process lifetime, refreshed 60 s before expiry.
3. **DST dedup** — `files(query: "filename:<name>")` on DST; hit → record as `already-in-dst`, skip.
4. **SRC resolve** — same query on SRC; hit → grab the first public `url` / `originalSource.url`, record as `missing-in-dst-resolved`.
5. **Upload** — for images: `fileCreate(files: [{ alt, filename, contentType, originalSource }])` in batches of 10. For videos: `stagedUploadsCreate(resource: VIDEO)` → multipart POST bytes to S3 → `fileCreate(originalSource: resourceUrl)`.
6. **Poll** — `nodes(ids:)` every 2 s up to 90 s; `READY` → `copied`, `FAILED` → `failed`, timeout → `timeout`.
7. **Manifest** — write JSON + CSV with every row's lookup + upload outcome to the global `.log/` (or `--manifest-out`).

`--force <names>` inserts an additional pre-DST-dedup pass that runs `fileDelete` on every DST record matching each name before the normal resolve+upload flow proceeds.

Details of the same algorithm in spec form (if the consumer repo uses OpenSpec): `openspec/specs/asset-sync-tool/spec.md`.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Missing or placeholder values in .env: SHOPIFY_SRC_STORE` | Ported `.env` still has old NA/PH variable names | Rename to `SRC_*` / `DST_*` in place |
| `shop_not_permitted on <store>` | App and store are in different Dev Dashboard orgs | Re-create the app inside the store's own org, reinstall, copy Client ID/Secret |
| `OAuth token exchange failed: HTTP 401` | Pasted an Admin access token (`shpat_…`) into `CLIENT_ID` or `CLIENT_SECRET` | Values MUST come from Dev Dashboard → App → Settings, not from Admin → Apps |
| `Invalid video url=…` during upload | Passed SRC CDN URL as `originalSource` for a `.mp4`/`.mov` | Tool auto-routes video extensions through staged upload — if you see this, extension-sniffing was skipped; add your extension to `mimeTypeFor` + `inferContentType` regexes |
| `fileCreate` succeeds but PDP still 404s for `/cdn/shop/files/EB.jpg` | DST stored the file under SRC's actual filename (e.g. UUID.jpg) not the requested `alt` | Re-run with `--force EB.jpg`; the new run passes explicit `filename:` to `fileCreate` |
| `Setting 'mp4_video_url' value does not point to an applicable shopify-hosted video resource.` from `shopify theme push` | Video was uploaded, but the template still references `shopify://files/videos/<name>` where the real file is under `shopify://files/<name>` (or vice-versa) | Manually re-pick the video in the Shopify theme editor → re-pull the template |
| `--scan matched zero files under <cwd>` | Running from wrong directory, or glob typo | `pwd` check; test the glob with `ls <pattern>` first |

## Files in this skill

- `SKILL.md` (this file) — agent instructions
- `sync.mjs` — the CLI
- `.env.example` — template for the active `.env`
- `README.md` — human-facing docs (duplicates most of this file for non-agent readers)
