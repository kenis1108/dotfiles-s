if has('vim9script')
  for script in glob('~/.config/vim/pluginvim9/*.vim', 1, 1)
    execute 'source' script
  endfor
endif
