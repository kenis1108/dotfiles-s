vim9script

g:mapleader = " "
g:maplocalleader = " "

# Move to window using the <ctrl> hjkl keys
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

# Resize window using <ctrl> arrow keys
nnoremap <C-Up> <cmd>resize +2<cr>
nnoremap <C-Down> <cmd>resize -2<cr>
nnoremap <C-Left> <cmd>vertical resize -2<cr>
nnoremap <C-Right> <cmd>vertical resize +2<cr>

# Move Lines
nnoremap <A-j> <cmd>execute 'move .+' .. v:count1<cr>==
nnoremap <A-k> <cmd>execute 'move .-' .. (v:count1 + 1)<cr>==
inoremap <A-j> <esc><cmd>m .+1<cr>==gi
inoremap <A-k> <esc><cmd>m .-2<cr>==gi
vnoremap <A-j> :<C-u>execute "'<,'>move '>+" .. v:count1<cr>gv=gv
vnoremap <A-k> :<C-u>execute "'<,'>move '<-" .. (v:count1 + 1)<cr>gv=gv

# Save File
nnoremap <C-s> <cmd>w<cr><esc>
inoremap <C-s> <cmd>w<cr><esc>
xnoremap <C-s> <cmd>w<cr><esc>
snoremap <C-s> <cmd>w<cr><esc>

# Quit All
nnoremap <C-q> <cmd>qa<cr>
nnoremap <leader>q <cmd>q<cr>

nnoremap <silent> <esc> <cmd>nohlsearch<cr><esc>
inoremap <silent> <esc> <cmd>nohlsearch<cr><esc>
snoremap <silent> <esc> <cmd>nohlsearch<cr><esc>

# Netrw
nnoremap <leader>e <cmd>Ve<cr>

# Use <leader>v to trigger visual block mode
nnoremap <leader>v <C-v>
vnoremap <leader>v <C-v>

nnoremap ; :
inoremap jk <esc>