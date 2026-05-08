local map = vim.keymap.set
local function nomap(mode, key)
  local ok, _ = pcall(vim.keymap.del, mode, key)
  if not ok then
    local msg = "nomap: " .. mode .. " " .. key .. " not found"
    vim.cmd("echomsg '" .. msg .. "'")
  end
end

if vim.env.NVIM_APPNAME then
  if vim.env.NVIM_APPNAME:find "nvchad" ~= nil then
    nomap("n", "<C-c>")
    nomap("n", "<leader>fa")
    nomap("n", "<leader>fb")
    nomap("n", "<leader>ff")
    nomap("n", "<leader>fh")
    nomap("n", "<leader>fo")
    nomap("n", "<leader>fw")
    nomap("n", "<leader>fz")
  end
  if vim.env.NVIM_APPNAME:find "lazyvim" ~= nil then
    nomap("n", "<leader>fe")
    nomap("n", "<leader>fE")
  end
end

-- better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

map("i", "<C-b>", "<ESC>^i", { desc = "move beginning of line" })
map("i", "<C-e>", "<End>", { desc = "move end of line" })
map("i", "<C-h>", "<Left>", { desc = "move left" })
map("i", "<C-l>", "<Right>", { desc = "move right" })
map("i", "<C-j>", "<Down>", { desc = "move down" })
map("i", "<C-k>", "<Up>", { desc = "move up" })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- Move Lines
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })

-- quit
map("n", "<C-q>", "<cmd>qa<cr>", { desc = "Quit All" })

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- windows
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })

-- file manager
if not vim.env.NVIM_APPNAME then
  map("n", "<leader>e", "<cmd>Ve<CR>", { desc = "Open Netrw" })
  map("v", "<leader>e", "<cmd>Ve<CR>", { desc = "Open Netrw" })
end

-- 使用 <leader>v 触发可视块模式
map({ "n", "v" }, "<leader>v", "<C-V>", { desc = "Visual Block Mode" })

function _G.toggle_background()
  local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal" })

  if normal_hl.bg and normal_hl.bg == 0x222436 then
    vim.api.nvim_set_hl(0, "Normal", {
      bg = nil,
      ctermbg = nil,
    })
    vim.api.nvim_set_hl(0, "SignColumn", {
      bg = nil,
    })
  else
    vim.api.nvim_set_hl(0, "Normal", {
      fg = 0xc8d3f5,
      bg = 0x222436,
    })
    vim.api.nvim_set_hl(0, "SignColumn", {
      fg = 0x3b4261,
      bg = 0x222436,
    })
  end
end
-- toggle background
map("n", "<leader>bg", "<cmd>lua toggle_background()<CR>", { desc = "Toggle Background" })

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })

map("n", "<leader>pd", function()
  local nap = vim
    .iter(vim.pack.get())
    :filter(function(x)
      return not x.active
    end)
    :map(function(x)
      return x.spec.name
    end)
    :totable()
  vim.pack.del(nap)
end, { desc = "Del Non-Active Plugins From Disk" })

-- lua
map("n", "<localleader>r", function() require("snacks.debug").run() end, { desc = "Run Lua" })
map("x", "<localleader>r", function() require("snacks.debug").run() end, { desc = "Run Lua" })
