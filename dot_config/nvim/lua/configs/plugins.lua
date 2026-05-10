local map = vim.keymap.set
local gh = function(x) return 'https://github.com/' .. x end

-- -------- theme --------
vim.pack.add({ gh('folke/tokyonight.nvim'), gh('nvim-mini/mini.icons') })
vim.cmd('colorscheme tokyonight')

-- -------- file manager --------
vim.pack.add({ gh('mikavilpas/yazi.nvim'), gh('nvim-lua/plenary.nvim') })
map("n", "<leader>e", function() require("yazi").yazi() end, { desc = "Open Yazi" })
vim.g.loaded_netrwPlugin = 1
vim.api.nvim_create_autocmd("UIEnter", {
  callback = function()
    require("yazi").setup({
      open_for_directories = true,
      keymaps = {
        show_help = "<f2>", -- 因为我的F1用来触发snipaste截图
      },
    })
  end,
})

-- -------- completion --------
vim.pack.add({ { src = gh('saghen/blink.cmp'), version = 'v1.8.0' }, gh('rafamadriz/friendly-snippets') })
require('blink.cmp').setup({
  completion = {
    menu = {
      draw = {
        columns = { { 'kind_icon', 'kind', gap = 1 }, { 'label', 'label_description', gap = 1 } },
      }
    },
  },
})

-- -------- LSP --------
-- 个人理解
-- nvim-lspconfig 是一些neovim官方预设的lsp配置文件，可以直接vim.lsp.enable('$lsp_name')。
-- mason.nvim 是一个安装和管理lsp、dap、linters、formatters工具的统一界面。
-- mason-lspconfig.nvim 用于自动启用nvim-lspconfig里有的且mason已安装的lsp。
vim.pack.add({ gh('neovim/nvim-lspconfig'), gh('mason-org/mason.nvim'), gh('mason-org/mason-lspconfig.nvim') })
local is_termux = vim.env.TERMUX_VERSION ~= nil
local ensure_installed = {
  "stylua",
}
if not is_termux then
  table.insert(ensure_installed, 'lua-language-server')
end
require('mason').setup()
require("mason-lspconfig").setup()
local mr = require "mason-registry"
-- 自动安装非 LSP 工具（Formatter、Linter、DAP 等）
mr.refresh(function()
  for _, tool in ipairs(ensure_installed) do
    local p = mr.get_package(tool)
    if not p:is_installed() then
      p:install()
    end
  end
end)

-- -------- others --------
vim.pack.add({ gh('nvim-mini/mini.pairs') })
require('mini.pairs').setup()

-- vim.pack.add({ gh('nvim-mini/mini.clue') })
-- local miniclue = require('mini.clue')
-- miniclue.setup({
--   triggers = {
--     -- Leader triggers
--     { mode = { 'n', 'x' }, keys = '<Leader>' },
--
--     -- `[` and `]` keys
--     { mode = 'n', keys = '[' },
--     { mode = 'n', keys = ']' },
--
--     -- Built-in completion
--     { mode = 'i', keys = '<C-x>' },
--
--     -- `g` key
--     { mode = { 'n', 'x' }, keys = 'g' },
--
--     -- Marks
--     { mode = { 'n', 'x' }, keys = "'" },
--     { mode = { 'n', 'x' }, keys = '`' },
--
--     -- Registers
--     { mode = { 'n', 'x' }, keys = '"' },
--     { mode = { 'i', 'c' }, keys = '<C-r>' },
--
--     -- Window commands
--     { mode = 'n', keys = '<C-w>' },
--
--     -- `z` key
--     { mode = { 'n', 'x' }, keys = 'z' },
--   },
--
--   clues = {
--     -- Enhance this by adding descriptions for <Leader> mapping groups
--     miniclue.gen_clues.square_brackets(),
--     miniclue.gen_clues.builtin_completion(),
--     miniclue.gen_clues.g(),
--     miniclue.gen_clues.marks(),
--     miniclue.gen_clues.registers(),
--     miniclue.gen_clues.windows(),
--     miniclue.gen_clues.z(),
--   },
-- })

vim.pack.add({ gh('folke/snacks.nvim') })
require('snacks').setup({
  picker = { enable = true },
  scroll = { enable = true }
})
map("n","<leader>f", function() Snacks.picker() end, { desc = "Open Snacks Picker" })
map("n", "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config") }) end, { desc = "Find Config File" })
map("n", "<leader>fd", function() Snacks.picker.files({ cwd = require("lazy.core.config").options.root or vim.fn.stdpath("data") }) end, { desc = "Find Plugins Data" })
map("n", "<leader>/c", function() Snacks.picker.grep({ cwd = vim.fn.stdpath("config") }) end, { desc = "Grep Config File" })
map("n", "<leader>/d", function() Snacks.picker.grep({ cwd = require("lazy.core.config").options.root or vim.fn.stdpath("data") }) end, { desc = "Grep Plugins Data" })

