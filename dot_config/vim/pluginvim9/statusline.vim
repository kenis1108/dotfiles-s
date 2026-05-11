vim9script

if exists("g:loaded_statusline")
  finish
endif
g:loaded_statusline = 1

def GetModeText(): string
  const mode_map = {
    'n': 'N',
    'i': 'I',
    'v': 'V',
    'V': 'V-L',
    "\<C-V>": 'V-B',
    'R': 'R',
    'c': 'C',
    't': 'T'
  }
  return get(mode_map, mode(), 'O')
enddef
defcompile

var last_git_status = ['', 0.0]  # [status, timestamp]

def GetGitStatus(): string
  # 使用缓存（2秒内有效）
  var now = reltimefloat(reltime())
  if now - last_git_status[1] < 2.0
    return last_git_status[0]
  endif

  if !executable('git') | return '' | endif

  # Windows 兼容方案
  var cmd = has('win32') ? 
    'git branch --show-current 2> nul' : 
    'git branch --show-current 2>/dev/null'

  var branch = system(cmd)->trim()
  var status = empty(branch) ? '' : ' ' .. branch
  
  # 更新缓存
  last_git_status = [status, now]
  
  return status
enddef
defcompile

def GetIndentInfo(): string
  return &expandtab ? 'space:' .. &shiftwidth : 'tab:' .. &tabstop
enddef
defcompile

def GetLineEnding(): string
  return &fileformat == 'dos' ? 'CRLF' : 'LF'
enddef
defcompile

def GetLSPStatus(): string
  if !exists('*lsp#buffer#BufHasLspServer')
    return 'NL'
  endif

  return lsp#buffer#BufHasLspServer(bufnr('%')) ? 'LSP' : 'NL'
enddef
defcompile

def SetupStatusline()
  # 定义高亮组（示例，可根据配色方案调整）
  highlight ModeText guifg=#4EC9B0 gui=bold
  highlight GitText guifg=#569CD6 gui=bold
  highlight SeparatorText guifg=#565f89 gui=bold
  highlight InfoText guifg=#C586C0 gui=bold
  highlight IndentText guifg=#FFA500 gui=bold
  highlight EncodingText guifg=#DCDCAA gui=bold
  highlight FileTypeText guifg=#4FC1FF gui=bold
  highlight LineEndingText guifg=#A9B7C6 gui=bold
  highlight LSPText guifg=#FF6B6B gui=bold
  highlight NormalText guifg=#CCCCCC

  # 将Vim9函数暴露给statusline
  def g:Statusline_Mode(): string
    return GetModeText()
  enddef

  def g:Statusline_Git(): string
    try
      return GetGitStatus()
    catch
      return ''
    endtry
  enddef

  def g:Statusline_Indent(): string
    return GetIndentInfo()
  enddef

  def g:Statusline_LineEnding(): string
    return GetLineEnding()
  enddef

  def g:Statusline_LSP(): string
    return GetLSPStatus()
  enddef

  # 设置statusline
  &statusline = ''
  &statusline ..= '%#ModeText#%{g:Statusline_Mode()}%#NormalText# '
  &statusline ..= '%#GitText#%{g:Statusline_Git()}%#NormalText# '
  &statusline ..= '%='
  &statusline ..= '%#InfoText#%l,%c%#NormalText# '
  &statusline ..= '%#IndentText#%{g:Statusline_Indent()}%#NormalText# '
  &statusline ..= '%#EncodingText#%{&fileencoding}%#NormalText# '
  &statusline ..= '%#FileTypeText#%{&filetype}%#NormalText# '
  &statusline ..= '%#LineEndingText#%{g:Statusline_LineEnding()}%#NormalText# '
  &statusline ..= '%#LSPText#%{g:Statusline_LSP()}%#NormalText#'

enddef
defcompile

SetupStatusline()
