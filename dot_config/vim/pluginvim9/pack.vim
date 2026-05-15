vim9script

if exists('g:loaded_pluginvim9_pack')
  finish
endif
g:loaded_pluginvim9_pack = 1

# Vim9script port of Neovim's experimental vim.pack API.
#
# Public API:
#
#   g:pack.add(specs, opts = {})
#   g:pack.get(names = v:none, opts = {})
#   g:pack.update(names = v:none, opts = {})
#   g:pack.del(names, opts = {})
#
# Specs intentionally match Neovim:
#
#   g:pack.add([
#     'https://github.com/tpope/vim-commentary',
#     {
#       src: 'https://github.com/tpope/vim-surround',
#       name: 'vim-surround',
#       version: 'main',
#       data: {lazy: false},
#     },
#   ], {
#     confirm: false,
#     load: true,
#   })
#
# Spec keys:
#
#   src       Required. Any source accepted by `git clone`.
#   name      Optional. Directory name. Defaults to the repository name derived
#             from src, without a trailing ".git".
#   version   Optional. Git branch, tag, or commit to checkout. Vim9 version
#             does not implement Neovim's vim.VersionRange objects.
#   data      Optional. Arbitrary user data preserved in active plugin info.
#
# add() opts:
#
#   load      Optional bool-like value or Funcref. Default follows Neovim's
#             shape as closely as Vim allows: false while starting, true after
#             VimEnter. true runs :packadd {name}; a Funcref receives
#             {spec, path}.
#   confirm   Optional bool-like value. Defaults to true.
#
# get() opts:
#
#   info      Optional bool-like value. Defaults to true. Adds `branches` and
#             `tags` by running git commands.
#
# update() opts:
#
#   force     Optional bool-like value. Defaults to false. Vim9 version does
#             not implement Neovim's confirmation buffer, so updates are only
#             applied when force is true.
#   offline   Optional bool-like value. Defaults to false. Skips git fetch.
#   target    Optional. "version" or "lockfile". Defaults to "version".
#
# del() opts:
#
#   force     Optional bool-like value. Defaults to false. Required to delete a
#             plugin that was added in the current Vim session.
#
# Managed paths:
#
#   Plugins:  {packroot}/pack/core/opt/{name}
#   Lockfile: {packroot}/vim-pack-lock.json
#
# Vim has no stdpath('data'), so the default plugin root is the first writable
# entry in 'packpath', falling back to ~/.vim. Tests or custom configs may set:
#
#   g:pluginvim9_pack_dir
#   g:pluginvim9_pack_lockfile
#
# Deliberate differences from Neovim:
#
#   - No async/parallel jobs.
#   - No semver VersionRange resolution.
#   - No update confirmation buffer.
#   - No PackChanged autocmd event data.
#   - Source changes follow Neovim's implementation: add() records the active
#     spec, and update({name}, {force: true}) changes the git remote.

var plugin_lock: dict<any> = {}
var lock_loaded = false
var active_plugins: dict<any> = {}
var active_order: list<string> = []

def Fail(message: string)
  throw 'pluginvim9.pack: ' .. message
enddef

def Text(value: any): string
  return type(value) == v:t_string ? value : string(value)
enddef

def Truthy(value: any): bool
  const value_type = type(value)
  if value_type == v:t_bool
    return value ? true : false
  endif
  if value_type == v:t_number
    return value != 0
  endif
  if value_type == v:t_string
    const lower = tolower(value)
    return index(['1', 'true', 'yes', 'on'], lower) >= 0
  endif
  return false
enddef

def DefaultLoad(): bool
  return exists('v:vim_did_enter') && v:vim_did_enter == 1
enddef

def PackRoot(): string
  for root in split(&packpath, ',')
    const expanded = expand(root)
    if empty(expanded)
      continue
    endif
    if isdirectory(expanded) && filewritable(expanded) == 2
      return expanded
    endif
    const parent = fnamemodify(expanded, ':h')
    if isdirectory(parent) && filewritable(parent) == 2
      return expanded
    endif
  endfor

  return expand('~/.vim')
enddef

def PluginRoot(): string
  if exists('g:pluginvim9_pack_dir')
    return expand(Text(g:pluginvim9_pack_dir))
  endif

  return PackRoot() .. '/pack/core/opt'
enddef

def LockPath(): string
  if exists('g:pluginvim9_pack_lockfile')
    return expand(Text(g:pluginvim9_pack_lockfile))
  endif

  return PackRoot() .. '/vim-pack-lock.json'
enddef

def EnsurePackpath()
  const site = fnamemodify(PluginRoot(), ':h:h:h')
  const parts = split(&packpath, ',')
  if index(mapnew(parts, (_, path) => expand(path)), site) < 0
    &packpath = site .. ',' .. &packpath
  endif
enddef

def ValidateName(name: string): string
  const clean = trim(name)
  if empty(clean) || clean ==# '.' || clean ==# '..' || clean =~# '[/\\]'
    Fail('invalid plugin name: ' .. string(name))
  endif
  return clean
enddef

def PluginName(src: string): string
  var name = substitute(src, '[?#].*$', '', '')
  name = substitute(name, '/\+$', '', '')
  name = fnamemodify(name, ':t')
  name = substitute(name, '\.git$', '', '')
  return ValidateName(name)
enddef

def NormalizeSpec(raw_spec: any): dict<any>
  var source_spec: dict<any>
  if type(raw_spec) == v:t_string
    source_spec = {src: raw_spec}
  elseif type(raw_spec) == v:t_dict
    source_spec = copy(raw_spec)
  else
    Fail('spec must be a string or dict')
  endif

  const src = get(source_spec, 'src', '')
  if type(src) != v:t_string || empty(src)
    Fail('spec.src must be a non-empty string')
  endif

  var name = get(source_spec, 'name', '')
  if empty(name)
    name = PluginName(src)
  endif
  if type(name) != v:t_string
    Fail('spec.name must be a string')
  endif

  var resolved = {
    src: src,
    name: ValidateName(name),
    version: get(source_spec, 'version', v:none),
    data: get(source_spec, 'data', v:none),
  }

  if type(resolved.version) != v:t_none && type(resolved.version) != v:t_string
    Fail('spec.version must be a string')
  endif

  return resolved
enddef

def NormalizeSpecs(specs: any): list<dict<any>>
  if type(specs) != v:t_list
    Fail('specs must be a list')
  endif

  var by_path: dict<any> = {}
  var order: list<string> = []

  for raw_spec in specs
    const spec = NormalizeSpec(raw_spec)
    const path = PluginPath(spec.name)
    if !has_key(by_path, path)
      by_path[path] = spec
      order->add(path)
      continue
    endif

    const current = by_path[path]
    if current.src !=# spec.src
      Fail('Conflicting `src` for `' .. spec.name .. "`:\n"
        .. current.src .. "\n" .. spec.src)
    endif
    if string(current.version) !=# string(spec.version)
      Fail('Conflicting `version` for `' .. spec.name .. "`:\n"
        .. string(current.version) .. "\n" .. string(spec.version))
    endif
  endfor

  return order->mapnew((_, path) => by_path[path])
enddef

def PluginPath(name: string): string
  return PluginRoot() .. '/' .. name
enddef

def Run(command: string, message = ''): string
  const output = system(command .. ' 2>&1')
  if v:shell_error != 0
    Fail((empty(message) ? 'command failed' : message) .. ":\n" .. command .. "\n" .. output)
  endif
  return trim(output)
enddef

def Git(path: string, args: string): string
  return Run('git -C ' .. shellescape(path) .. ' ' .. args)
enddef

def GitEnsure()
  if !executable('git')
    Fail('No `git` executable')
  endif
enddef

def GitHash(path: string, ref = 'HEAD'): string
  return Git(path, 'rev-list -1 ' .. shellescape(ref))
enddef

def GitRemote(path: string): string
  return Git(path, 'remote get-url origin')
enddef

def GitDefaultBranch(path: string): string
  const branch = Git(path, 'rev-parse --abbrev-ref origin/HEAD')
  return substitute(branch, '^origin/', '', '')
enddef

def GitBranches(path: string): list<string>
  const output = Git(path, 'branch --remote --list --format='
    .. shellescape('%(refname:short)') .. ' -- ' .. shellescape('origin/**'))
  var branches: list<string> = []
  const default_branch = GitDefaultBranch(path)
  for line in split(output, "\n")
    const branch = substitute(line, '^origin/', '', '')
    if empty(branch) || branch ==# 'HEAD'
      continue
    endif
    if branch ==# default_branch
      branches->insert(branch, 0)
    else
      branches->add(branch)
    endif
  endfor
  return branches
enddef

def GitTags(path: string): list<string>
  const output = Git(path, 'tag --list --sort=-v:refname')
  return empty(output) ? [] : split(output, "\n")
enddef

def GitCheckout(path: string, spec: dict<any>): string
  var ref: string
  if type(spec.version) == v:t_none
    ref = 'origin/' .. GitDefaultBranch(path)
  else
    const version = Text(spec.version)
    const branches = GitBranches(path)
    ref = index(branches, version) >= 0 ? 'origin/' .. version : version
  endif

  const rev = GitHash(path, ref)
  Git(path, 'checkout --quiet ' .. shellescape(rev))
  Git(path, 'submodule update --init --recursive')
  BuildHelptags(path)
  return rev
enddef

def BuildHelptags(path: string)
  const doc = path .. '/doc'
  if isdirectory(doc)
    silent! execute 'helptags ' .. fnameescape(doc)
  endif
enddef

def EmptyLock(): dict<any>
  return {plugins: {}}
enddef

def LockRead(confirm = true, specs: list<dict<any>> = [])
  if lock_loaded
    return
  endif

  const lock_path = LockPath()
  if filereadable(lock_path)
    try
      plugin_lock = json_decode(join(readfile(lock_path), "\n"))
    catch
      plugin_lock = EmptyLock()
    endtry
  else
    plugin_lock = EmptyLock()
  endif

  if type(plugin_lock) != v:t_dict || type(get(plugin_lock, 'plugins', {})) != v:t_dict
    plugin_lock = EmptyLock()
  endif

  lock_loaded = true
  LockSync(confirm, specs)
enddef

def LockWrite()
  const lock_path = LockPath()
  mkdir(fnamemodify(lock_path, ':h'), 'p')
  writefile(split(json_encode(plugin_lock), "\n"), lock_path)
enddef

def SetLockVersion(lock_data: dict<any>, version: any)
  if type(version) == v:t_none
    if has_key(lock_data, 'version')
      remove(lock_data, 'version')
    endif
  else
    lock_data.version = version
  endif
enddef

def LockSync(confirm: bool, specs: list<dict<any>>)
  mkdir(PluginRoot(), 'p')

  var changed = false
  for name in keys(plugin_lock.plugins)
    const path = PluginPath(name)
    if !isdirectory(path)
      const lock_data = plugin_lock.plugins[name]
      if type(lock_data) == v:t_dict
        var spec = {src: get(lock_data, 'src', ''), name: name, version: get(lock_data, 'version', v:none)}
        for user_spec in specs
          if user_spec.name ==# name
            spec = copy(user_spec)
          endif
        endfor
        if !empty(spec.src)
          Install(spec, confirm)
          changed = true
        endif
      endif
    elseif type(plugin_lock.plugins[name]) != v:t_dict
      plugin_lock.plugins[name] = {}
      RepairLock(name)
      changed = true
    endif
  endfor

  if changed
    LockWrite()
  endif
enddef

def RepairLock(name: string)
  const path = PluginPath(name)
  if !isdirectory(path)
    remove(plugin_lock.plugins, name)
    return
  endif

  plugin_lock.plugins[name] = {
    rev: GitHash(path),
    src: GitRemote(path),
  }
enddef

def ConfirmInstall(plugs: list<dict<any>>): bool
  if empty(plugs)
    return true
  endif

  var lines: list<string> = []
  for plug in plugs
    lines->add(plug.name .. ' from ' .. plug.src)
  endfor

  const choice = confirm("These plugins will be installed:\n\n"
    .. join(lines, "\n") .. "\n", "Proceed? &Yes\n&No", 1)
  return choice != 2
enddef

def Install(spec: dict<any>, confirm_install: bool): bool
  GitEnsure()
  const path = PluginPath(spec.name)

  if isdirectory(path)
    return true
  endif

  if confirm_install && !ConfirmInstall([spec])
    return false
  endif

  try
    mkdir(fnamemodify(path, ':h'), 'p')
    Run('git clone --quiet --no-checkout --origin origin '
      .. shellescape(spec.src) .. ' ' .. shellescape(path), 'git clone failed')

    const rev = GitCheckout(path, spec)
    var lock_data = {
      rev: rev,
      src: spec.src,
    }
    SetLockVersion(lock_data, spec.version)
    plugin_lock.plugins[spec.name] = lock_data
  catch
    delete(path, 'rf')
    if has_key(plugin_lock.plugins, spec.name)
      remove(plugin_lock.plugins, spec.name)
    endif
    throw v:exception
  endtry
  return true
enddef

def PackAdd(spec: dict<any>, load: any)
  const path = PluginPath(spec.name)
  if has_key(active_plugins, path)
    return
  endif

  active_plugins[path] = {spec: spec, path: path}
  active_order->add(path)

  if type(load) == v:t_func
    call(load, [{spec: copy(spec), path: path}])
    return
  endif

  execute 'packadd' .. (Truthy(load) ? ' ' : '! ') .. spec.name->escape(' ')
enddef

def RemoveActive(path: string)
  if has_key(active_plugins, path)
    remove(active_plugins, path)
  endif
  var next_order: list<string> = []
  for active_path in active_order
    if active_path !=# path
      next_order->add(active_path)
    endif
  endfor
  active_order = next_order
enddef

def PlugInfo(name: string, include_info: bool): dict<any>
  const lock_data = plugin_lock.plugins[name]
  const path = PluginPath(name)
  var spec = {
    src: get(lock_data, 'src', ''),
    name: name,
    version: get(lock_data, 'version', v:none),
    data: v:none,
  }
  var active = false
  if has_key(active_plugins, path)
    spec = copy(active_plugins[path].spec)
    active = true
  endif

  var data = {
    spec: spec,
    path: path,
    rev: get(lock_data, 'rev', ''),
    active: active,
  }

  if include_info
    data.branches = GitBranches(path)
    data.tags = GitTags(path)
  endif

  return data
enddef

def NamesFromArg(names: any): list<string>
  if type(names) == v:t_none
    return sort(keys(plugin_lock.plugins))
  endif
  if type(names) != v:t_list
    Fail('names must be a list')
  endif
  return copy(names)->mapnew((_, name) => Text(name))
enddef

def g:Pluginvim9PackAdd(specs: any, opts: dict<any> = {})
  const resolved_opts = extend({load: DefaultLoad(), confirm: true}, opts)
  const spec_list = NormalizeSpecs(specs)

  EnsurePackpath()
  LockRead(Truthy(resolved_opts.confirm), spec_list)

  var to_install: list<dict<any>> = []
  var changed = false
  for spec in spec_list
    const lock_data = get(plugin_lock.plugins, spec.name, {})
    if type(lock_data) != v:t_dict || !isdirectory(PluginPath(spec.name))
      to_install->add(spec)
    endif

    var next_lock = type(lock_data) == v:t_dict ? copy(lock_data) : {}
    if string(get(next_lock, 'version', v:none)) !=# string(spec.version)
      changed = true
    endif
    SetLockVersion(next_lock, spec.version)
    plugin_lock.plugins[spec.name] = next_lock
  endfor

  changed = changed || !empty(to_install)
  if !empty(to_install)
    if !Truthy(resolved_opts.confirm) || ConfirmInstall(to_install)
      for spec in to_install
        if Install(spec, false)
          changed = true
        endif
      endfor
    endif

    for spec in to_install
      if !isdirectory(PluginPath(spec.name)) && has_key(plugin_lock.plugins, spec.name)
        remove(plugin_lock.plugins, spec.name)
        changed = true
      endif
    endfor
  endif

  for spec in spec_list
    if isdirectory(PluginPath(spec.name))
      if !has_key(plugin_lock.plugins[spec.name], 'rev')
        RepairLock(spec.name)
        changed = true
      endif
      PackAdd(spec, resolved_opts.load)
    endif
  endfor

  if changed
    LockWrite()
  endif
enddef

def g:Pluginvim9PackGet(names: any = v:none, opts: dict<any> = {}): list<dict<any>>
  const resolved_opts = extend({info: true}, opts)
  LockRead()
  if Truthy(resolved_opts.info)
    GitEnsure()
  endif

  const selected_names = NamesFromArg(names)
  var result: list<dict<any>> = []

  if type(names) != v:t_none
    for name in selected_names
      if !has_key(plugin_lock.plugins, name)
        Fail('Plugin `' .. name .. '` is not installed')
      endif
      result->add(PlugInfo(name, Truthy(resolved_opts.info)))
    endfor
    return result
  endif

  var active_seen: dict<bool> = {}
  for path in active_order
    if !has_key(active_plugins, path)
      continue
    endif
    const name = active_plugins[path].spec.name
    if !has_key(plugin_lock.plugins, name)
      continue
    endif
    result->add(PlugInfo(name, Truthy(resolved_opts.info)))
    active_seen[name] = true
  endfor

  for name in selected_names
    if has_key(active_seen, name)
      continue
    endif
    result->add(PlugInfo(name, Truthy(resolved_opts.info)))
  endfor

  return result
enddef

def g:Pluginvim9PackUpdate(names: any = v:none, opts: dict<any> = {})
  const resolved_opts = extend({force: false, offline: false, target: 'version'}, opts)
  if resolved_opts.target !=# 'version' && resolved_opts.target !=# 'lockfile'
    Fail('opts.target must be "version" or "lockfile"')
  endif
  if !Truthy(resolved_opts.force)
    Fail('update confirmation buffer is not implemented; call update(..., {force: true})')
  endif

  LockRead()
  GitEnsure()

  var changed = false
  for name in NamesFromArg(names)
    if !has_key(plugin_lock.plugins, name)
      Fail('Plugin `' .. name .. '` is not installed')
    endif

    const path = PluginPath(name)
    if !isdirectory(path)
      Fail('Plugin `' .. name .. '` is missing on disk')
    endif

    const lock_data = plugin_lock.plugins[name]
    const active_spec = has_key(active_plugins, path) ? active_plugins[path].spec : {}
    var spec = !empty(active_spec) ? copy(active_spec) : {
      src: get(lock_data, 'src', ''),
      name: name,
      version: get(lock_data, 'version', v:none),
      data: v:none,
    }
    if get(lock_data, 'src', '') !=# spec.src
      Git(path, 'remote set-url origin ' .. shellescape(spec.src))
      lock_data.src = spec.src
      changed = true
    endif
    if !Truthy(resolved_opts.offline)
      Git(path, 'fetch --quiet --tags --force --recurse-submodules=yes origin')
    endif
    if resolved_opts.target ==# 'lockfile'
      const rev = get(lock_data, 'rev', '')
      if empty(rev)
        Fail('Plugin `' .. name .. '` has no lockfile revision')
      endif
      Git(path, 'checkout --quiet ' .. shellescape(rev))
      BuildHelptags(path)
    else
      const rev = GitCheckout(path, spec)
      if get(lock_data, 'rev', '') !=# rev
        lock_data.rev = rev
        changed = true
      endif
    endif
  endfor

  if changed
    LockWrite()
  endif
enddef

def g:Pluginvim9PackDel(names: any, opts: dict<any> = {})
  const resolved_opts = extend({force: false}, opts)
  LockRead()

  if type(names) != v:t_list
    Fail('names must be a list')
  endif

  var failed: list<string> = []
  for raw_name in names
    const name = Text(raw_name)
    if !has_key(plugin_lock.plugins, name)
      continue
    endif

    const path = PluginPath(name)
    if has_key(active_plugins, path) && !Truthy(resolved_opts.force)
      failed->add(name)
      continue
    endif

    delete(path, 'rf')
    remove(plugin_lock.plugins, name)
    if has_key(active_plugins, path)
      RemoveActive(path)
    endif
  endfor

  LockWrite()

  if !empty(failed)
    Fail('Some plugins are active and were not deleted: ' .. join(failed, ', ')
      .. '. Remove them from vimrc, restart, and try again.')
  endif
enddef

if !exists('g:pack') || type(g:pack) != v:t_dict
  g:pack = {}
endif
g:pack.add = function('g:Pluginvim9PackAdd')
g:pack.get = function('g:Pluginvim9PackGet')
g:pack.update = function('g:Pluginvim9PackUpdate')
g:pack.del = function('g:Pluginvim9PackDel')
