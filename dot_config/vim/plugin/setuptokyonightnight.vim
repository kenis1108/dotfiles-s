" 下载 tokyonight-night 到第一个 runtimepath 的 colors 目录
function! InstallTheme()
  " 只取 RTP 第一个路径
  let l:first_rtp = split(&rtp, ',')[0]
  let l:colors_dir = l:first_rtp . '/colors'
  let l:target = l:colors_dir . '/tokyonight-night.vim'
  let l:url = 'https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/vim/colors/tokyonight-night.vim'

  " 不存在则创建 colors 目录
  if !isdirectory(l:colors_dir)
    call mkdir(l:colors_dir, 'p')
  endif

  " 文件不存在时才下载
  if !filereadable(l:target)
    echo '⬇️ 正在下载主题...'
    if executable('curl')
      silent execute '!curl -fLo ' . shellescape(l:target) . ' ' . shellescape(l:url)
    elseif executable('wget')
      silent execute '!wget -O ' . shellescape(l:target) . ' ' . shellescape(l:url)
    else
      echoerr '❌ 未找到 curl/wget，无法下载'
      return
    endif
  endif

  " 读取文件内容
  let l:lines = readfile(l:target)

  " 注释掉会覆盖自定义背景的高亮
  let l:bg_override_groups = ['Normal', 'SignColumn', 'VertSplit', 'WinSeparator']
  let l:patched_lines = []
  for l:line in l:lines
    if l:line =~# '^\s*hi clear\s*$'
      call add(l:patched_lines, '" hi clear  " 自动注释避免覆盖自定义高亮')
    else
      let l:hi_match = matchlist(l:line, '^\s*\("\s*\)\?hi\s\+\(\S\+\)')
      if empty(l:hi_match) || index(l:bg_override_groups, l:hi_match[2]) < 0
        call add(l:patched_lines, l:line)
      elseif l:hi_match[1] !=# '' || l:line =~# '^\s*hi\s\+' . l:hi_match[2] . '\s\+NONE\s*$'
        call add(l:patched_lines, l:line)
      else
        call add(l:patched_lines, '" ' . l:line)
        call add(l:patched_lines, 'hi ' . l:hi_match[2] . ' NONE')
      endif
    endif
  endfor
  let l:lines = l:patched_lines

  " 末尾追加来源注释
  let l:note = '" Download from https://github.com/folke/tokyonight.nvim/blob/main/extras/vim/colors/tokyonight-night.vim'
  if index(l:lines, l:note) < 0
    let l:lines += [l:note]
  endif

  " 写回文件
  call writefile(l:lines, l:target)
endfunction

call InstallTheme()
