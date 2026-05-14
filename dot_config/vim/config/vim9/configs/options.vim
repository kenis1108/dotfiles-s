vim9script

set mouse=a

# set autochdir

set termguicolors

# set updatetime=300

set belloff=all

set laststatus=2

set nocompatible
set noswapfile

set backspace=indent,eol,start

set scrolloff=4
set number relativenumber
set signcolumn=yes
# set fillchars=foldopen:,foldclose:,fold:\ ,foldsep:\ ,diff:╱,eob:\
set cursorline
set cursorlineopt=both

set encoding=utf-8
set fileencoding=utf-8

&clipboard = exists('$SSH_TTY') ? '' : 'unnamed,unnamedplus'

set hlsearch
set incsearch
set ignorecase
set smartcase

set shiftwidth=2
set tabstop=2
set expandtab
set shiftround
set colorcolumn=80

set wrap
set textwidth=0
set wrapmargin=0
set breakindent

set foldmethod=indent
set foldlevel=99

set confirm
set autoread
set autowrite
set autocomplete

set splitright
set splitbelow
set splitkeep=screen

set modeline
set modelines=1
set secure

set wildmenu
set wildmode=longest:full,full
set completeopt=menu,menuone,noselect

set list
set listchars=tab:»\ ,nbsp:␣,trail:·,eol:\ 

filetype plugin indent on
syntax enable
