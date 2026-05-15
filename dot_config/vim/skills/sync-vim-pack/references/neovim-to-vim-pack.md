# Neovim pack.lua to Vim9 pack.vim Mapping

## Critical Path Mapping

Neovim `vim.pack` manages plugins under:

```text
stdpath('data')/site/pack/core/opt/{name}
```

Vim does not have `stdpath('data')`. Do not invent a Vim `{data}` directory and do not hardcode `site/pack/core/opt` as the default.

The Vim port must default to:

```text
{first writable &packpath entry}/pack/core/opt/{name}
```

Fallback only when no writable `&packpath` entry exists:

```text
~/.vim/pack/core/opt/{name}
```

The lockfile should live beside the selected pack root by default:

```text
{first writable &packpath entry}/vim-pack-lock.json
```

Keep explicit overrides:

```vim
g:pluginvim9_pack_dir
g:pluginvim9_pack_lockfile
```

## API Mapping

| Neovim | Vim port |
|---|---|
| `vim.pack.add(specs, opts)` | `g:pack.add(specs, opts)` |
| `vim.pack.get(names, opts)` | `g:pack.get(names, opts)` |
| `vim.pack.update(names, opts)` | `g:pack.update(names, opts)` |
| `vim.pack.del(names, opts)` | `g:pack.del(names, opts)` |

Do not add an Ex command wrapper. Neovim exposes `vim.pack` as Lua API; Vim port exposes `g:pack` as Vimscript/Vim9 API.

## Spec Mapping

Preserve these fields:

```vim
{
  src: 'git-url-or-path',
  name: 'optional-name',
  version: 'optional-branch-tag-or-commit',
  data: any,
}
```

Differences:

- Neovim accepts `vim.VersionRange`; Vim port should not pretend to support it unless implemented explicitly.
- Keep string branch/tag/commit support.
- Preserve `data` in active plugin info even if the Vim port does not use it internally.

## Behavioral Mapping

- `add()` installs missing plugins, records lock data, registers active plugins, and calls `packadd` or `packadd!` according to `load`.
- `get()` returns active plugins first when names are omitted, then inactive lockfile plugins by name order.
- `update()` should update remote source after config changes and then fetch/checkout. Neovim applies source changes during update, not by immediate same-session replacement in `add()`.
- `del()` must reject active plugins unless `force` is true.
- Failed or canceled installs must not leave stale lock entries.

## Vim API Substitutions

| Neovim primitive | Vim9 substitute |
|---|---|
| `vim.system()` | `system()` with shellescaped command strings |
| `vim.fs.joinpath()` | string path joins |
| `vim.fs.rm()` | `delete(path, 'rf')` |
| `vim.fn.stdpath('data')` | first writable `&packpath` entry |
| `vim.fn.stdpath('config')` | avoid as default; use packroot lockfile unless overridden |
| `vim.cmd.packadd({bang=...})` | `execute 'packadd'` / `execute 'packadd!'` |
| async jobs | synchronous operations |
| confirmation update buffer | unsupported unless implemented deliberately |

## Validation Checklist

Run at least:

```sh
vim --clean -Nu NONE --not-a-term -es -S pluginvim9/pack.vim -c 'qa'
vim --clean -Nu NONE --not-a-term -es -S plugin/pluginvim9.vim -c 'qa'
```

When behavior changes, create local temporary git repositories and validate:

- `add()` clones and writes lockfile.
- `add(..., {load: true})` loads `plugin/`.
- `get(..., {info: false})` works without collecting branches/tags.
- `get()` with default info collects branches/tags.
- `update(..., {force: true})` updates revision and remote source.
- `del()` rejects active plugins unless forced.
- default install path is `{packpath-entry}/pack/core/opt/{name}`, not a Neovim `stdpath('data')` path.
