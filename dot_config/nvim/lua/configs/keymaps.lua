vim.g.mapleader = " "
if not vim.g.lazy_did_setup then
  vim.g.maplocalleader = "\\"
end

local map = vim.keymap.set

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
	map({ "n", "v" }, "<leader>e", "<cmd>Ve<CR>", { desc = "Open Netrw" })
end

-- 使用 <leader>v 触发可视块模式
map({ "n", "v" }, "<leader>v", "<C-V>", { desc = "Visual Block Mode" })

-- 支持写法：
-- "Normal"        精确匹配
-- "StatusLine*"   以 StatusLine 开头
-- "lualine_*"     以 lualine_ 开头
local hlgroups_glassy = {
	"Normal",
	"SignColumn",
	"StatusLine*",
	"lualine_c_*",
	"lualine_x_*",
}

local hl_original = {}

-- 把模糊规则展开成真实存在的 hlgroup 列表
local function expand_patterns(patterns)
	local all_hl = vim.api.nvim_get_hl(0, {})
	local result = {}

	for _, pat in ipairs(patterns) do
		-- 转成 Lua 匹配模式 * → .*
		local lua_pat = "^" .. pat:gsub("%*", ".*") .. "$"

		for name in pairs(all_hl) do
			if name:match(lua_pat) then
				result[name] = true
			end
		end
	end

	local list = {}
	for name in pairs(result) do
		table.insert(list, name)
	end
	return list
end

local function save_original_hl()
	if next(hl_original) ~= nil then
		return
	end
	local hl_list = expand_patterns(hlgroups_glassy)
	for _, name in ipairs(hl_list) do
		hl_original[name] = vim.api.nvim_get_hl(0, { name = name, link = false })
	end
end

function _G.toggle_background()
	save_original_hl()
	local current_normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
	local hl_list = expand_patterns(hlgroups_glassy)

	if current_normal.bg then
		for _, name in ipairs(hl_list) do
			vim.api.nvim_set_hl(0, name, { bg = nil, ctermbg = nil })
		end
	else
		for name, hl in pairs(hl_original) do
			vim.api.nvim_set_hl(0, name, hl)
		end
	end
end
-- toggle background
map("n", "<leader>bg", "<cmd>lua toggle_background()<CR>", { desc = "Toggle Background" })

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })

map("n", "<leader>pd", function()
	local nap = vim.iter(vim.pack.get())
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
map({ "n", "x" }, "<localleader>r", function()
	require("snacks.debug").run()
end, { desc = "Run Lua" })
