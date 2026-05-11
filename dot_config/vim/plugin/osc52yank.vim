" copy from https://www.zhihu.com/question/21132618
" if you use tmux, please open set-clipboard
" https://github.com/ojroques/vim-oscyank And you can install the plugin vim-oscyank, which has already realized the same functionality.

if exists('g:loaded_osc52yank')
  finish
endif
let g:loaded_osc52yank = 1

function OSC52Copy()
  let c = join(v:event.regcontents,"\n")
  let c64 = system("base64", c)
  let s = "\e]52;c;" . trim(c64) . "\x07"
  call s:raw_echo(s)
endfunction

function! s:raw_echo(str)
  if has('win32') && has('nvim')
    call chansend(v:stderr, a:str)
  else
    if filewritable('/dev/fd/2')
      call writefile([a:str], '/dev/fd/2', 'b')
    else
      exec("silent! !echo " . shellescape(a:str))
      redraw!
    endif
  endif
endfunction

if exists('$SSH_TTY')
  augroup OSC52Yank
    autocmd!
    autocmd TextYankPost * call OSC52Copy()
  augroup END
endif