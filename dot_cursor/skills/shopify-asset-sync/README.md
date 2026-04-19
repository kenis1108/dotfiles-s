# shopify-asset-sync

Node CLI that copies Shopify Files (images + videos) from one source store to one destination store, keyed by filename. Packaged as a global Cursor skill at `~/.cursor/skills/shopify-asset-sync/` so every shopify regional repo invokes the same binary against one shared `.env`.

See `SKILL.md` for the full reference used by Cursor agents (invocation cookbook, algorithm overview, troubleshooting table). This README is a human-oriented quick-start.

## Setup

```bash
# 1. Create apps in the Shopify Dev Dashboard (one per store org) — the app
#    and the store must live in the same org, otherwise OAuth returns
#    shop_not_permitted. Grant read_files on SRC, read_files+write_files on DST.

# 2. Provision .env:
cp ~/.cursor/skills/shopify-asset-sync/.env.example ~/.cursor/skills/shopify-asset-sync/.env
chmod 600 ~/.cursor/skills/shopify-asset-sync/.env
# edit the six SHOPIFY_{SRC,DST}_* variables
```

## Usage

```bash
# Dry-run against one template in the current repo (no writes):
cd ~/Documents/repo/shopify-theme-a
node ~/.cursor/skills/shopify-asset-sync/sync.mjs --scan 'templates/product.125w.json'

# Apply the upload (missing files only; DST-dedup is idempotent):
node ~/.cursor/skills/shopify-asset-sync/sync.mjs --scan 'templates/product.125w.json' --apply

# Multi-glob, comma-joined:
node ~/.cursor/skills/shopify-asset-sync/sync.mjs \
  --scan 'templates/product.*.json,sections/**/*.liquid' --apply

# Ghost-file recovery (see SKILL.md → Cookbook → "Ghost-file recovery"):
node ~/.cursor/skills/shopify-asset-sync/sync.mjs \
  --scan 'templates/product.d3-eb.json' \
  --apply --force 'EB.jpg,LFP_compression.jpg'

# PR-friendly manifest outside the global .log/:
node ~/.cursor/skills/shopify-asset-sync/sync.mjs \
  --scan 'templates/product.125w.json' \
  --manifest-out /tmp/pr-attachment/

# Override which .env to use (e.g. different region pairs):
node ~/.cursor/skills/shopify-asset-sync/sync.mjs \
  --scan '...' --env ~/.cursor/skills/shopify-asset-sync/na-to-uk.env
```

`node ~/.cursor/skills/shopify-asset-sync/sync.mjs --help` prints the full CLI reference and the active `SKILL_VERSION`.

## Layout

| File | Purpose |
|---|---|
| `SKILL.md` | Agent-facing instructions (frontmatter triggers + cookbook + troubleshooting) |
| `sync.mjs` | The CLI — single-file, Node 18+, no deps |
| `.env.example` | Template for `.env` (copy to `.env` and fill in) |
| `.env` | Active credentials (`chmod 600`, never in any git repo) |
| `.log/` | Manifest output (`.json` + `.csv` per run) — `--manifest-out` overrides |
| `README.md` | This file |

## Defaults

- `.env` path: `~/.cursor/skills/shopify-asset-sync/.env` — override with `--env <path>`
- Manifest dir: `~/.cursor/skills/shopify-asset-sync/.log/` — override with `--manifest-out <dir>`
- Scan root: `process.cwd()` (i.e. the repo you're invoking from)
- Upload batch: 10; poll timeout: 90 s; confirm sleep: 5 s (hardcoded in `sync.mjs`)

## Exit codes

- `0` clean run
- `1` at least one upload `failed` / `timeout`, or `missing-in-src` entries recorded
- `2` config error (missing env var, unmatched `--scan`, `shop_not_permitted`, …)

## Updating the skill

This directory is a plain folder — overwrite `sync.mjs` to patch, bump the `SKILL_VERSION` constant at the top, and verify with:

```bash
node ~/.cursor/skills/shopify-asset-sync/sync.mjs --help | head -1
```

No build step, no package manager. If a future feature needs a dep, add a `package.json` + `npm install` step here (and document it in `SKILL.md`).
