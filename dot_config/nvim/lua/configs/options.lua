-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
-- Make line numbers default
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)

local is_ssh = os.getenv('SSH_TTY') or os.getenv('SSH_CLIENT') or os.getenv('SSH_CONNECTION')
local my_paste = function(reg) return function(lines) return vim.split(vim.fn.getreg('"'), '\n') end end
if is_ssh then
  print('is_ssh',is_ssh)
  vim.g.clipboard = {
    name = 'OSC 52',
    copy = {
      ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
      ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
    },
    paste = {
      -- ['+'] = require('vim.ui.clipboard.osc52').paste('+'),
      -- ['*'] = require('vim.ui.clipboard.osc52').paste('*'),
      ['+'] = my_paste('+'),
      ['*'] = my_paste('*'),
    },
  }
end

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update time
vim.opt.updatetime = 250

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- display certain whitespace characters in the editor.
vim.opt.list = true

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Highlight Current Line
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- raise a dialog asking if you wish to save the current file(s)
vim.opt.confirm = true

-- default shell
-- vim.opt.shell = "powershell.exe"

-- default indent
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.expandtab = true
vim.opt.colorcolumn = 80

-- fold
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99

-- modeline
vim.opt.modeline = true
vim.opt.modelines = 2

-- 检查是否为 Windows 系统
if vim.fn.has('win32') == 1 then
  -- 检测 pwsh 是否存在
  local pwsh_exists = vim.fn.executable('pwsh') == 1

  -- 选择合适的 shell
  local shell = pwsh_exists and 'pwsh.exe' or 'powershell.exe'

  -- 配置终端选项
  vim.opt.shell = shell
  vim.opt.shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
  vim.opt.shellredir = '-RedirectStandardOutput %s -NoNewWindow -Wait'
  vim.opt.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
  vim.opt.shellquote = ''
  vim.opt.shellxquote = ''
end

-- vim.opt.autocomplete = true
-- vim.opt.completeopt:append({ "menuone", "noselect", "popup" })

vim.opt.autochdir = true
