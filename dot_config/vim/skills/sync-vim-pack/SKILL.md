---
name: sync-vim-pack
description: "Synchronize pluginvim9/pack.vim, a Vim9script port of Neovim's runtime lua/vim/pack.lua. Use when the user provides a new Neovim pack.lua or asks to update, realign, diff, or re-port pack.vim against Neovim vim.pack behavior. Critical: preserve Vim package semantics; Vim has no stdpath('data'), so never copy Neovim's stdpath('data')/site/pack/core/opt default directly."
---

# Sync Vim Pack

## Overview

Use this skill to update `pluginvim9/pack.vim` from a provided Neovim `runtime/lua/vim/pack.lua`. Treat Neovim as the behavioral source of truth, then adapt only where Vim lacks equivalent APIs.

## Workflow

1. Locate inputs:
   - Current Vim port: `pluginvim9/pack.vim`
   - New Neovim source: user-provided `pack.lua` path or contents

2. Read the mapping reference:
   - Load `references/neovim-to-vim-pack.md` before editing.
   - Pay special attention to the `stdpath('data')` rule.

3. Compare APIs and behavior:
   - Public API names: `add`, `get`, `update`, `del`
   - Spec fields: `src`, `name`, `version`, `data`
   - Option defaults and return values
   - Lockfile fields and source-update behavior
   - Active plugin tracking

4. Patch `pack.vim` surgically:
   - Keep Vim9script style and current helper organization unless a Neovim change requires otherwise.
   - Port behavior, not Lua implementation structure.
   - Do not add Ex commands; Neovim `vim.pack` is a Lua API and Vim port exposes `g:pack`.

5. Validate:
   - Source check: `vim --clean -Nu NONE --not-a-term -es -S pluginvim9/pack.vim -c 'qa'`
   - Loader check: `vim --clean -Nu NONE --not-a-term -es -S plugin/pluginvim9.vim -c 'qa'`
   - Run or recreate local-git tests for `add/get/update/del` if behavior changed.

## Non-Negotiables

- Do not map Neovim `stdpath('data')` to a fake Vim data directory.
- Default Vim plugin root must be based on Vim package rules: first writable `&packpath` entry, then `pack/core/opt/{name}`.
- Keep `g:pluginvim9_pack_dir` and `g:pluginvim9_pack_lockfile` override hooks unless the user explicitly removes them.
- Keep destructive operations limited to the managed plugin directory.
- Prefer source-compatible user API over feature completeness when Vim lacks Neovim primitives.

## Expected Shape

The Vim port should expose:

```vim
g:pack.add(specs, opts = {})
g:pack.get(names = v:none, opts = {})
g:pack.update(names = v:none, opts = {})
g:pack.del(names, opts = {})
```

If Neovim adds a new public `vim.pack` function, add a Vim equivalent only if it can be implemented coherently with Vim primitives. Otherwise document the unsupported gap in comments near the API.
