local DEBUG = true

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
-- map("n", "<leader>e", "<cmd>Ve<CR>", { desc = "Open Netrw" })
-- map("v", "<leader>e", "<cmd>Ve<CR>", { desc = "Open Netrw" })
-- map("n", "<leader>e", "<cmd>Yazi cwd<cr>", { desc = "Open Yazi in working directory" })
-- map("v", "<leader>e", "<cmd>Yazi cwd<cr>", { desc = "Open Yazi in working directory" })

-- telescope
map("n", "<leader>fb", "<cmd>Telescope builtin<cr>", { desc = "telescope find builtin" })
map("n", "<leader>fc", function()
	require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
end, { desc = "telescope find config" })
map("n", "<leader>fd", function()
	require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root or vim.fn.stdpath('data') })
end, { desc = "telescope find data" })
map("n", "<leader>/c", function()
	require("telescope.builtin").live_grep({ cwd = vim.fn.stdpath("config") })
end, { desc = "telescope live grep config" })
map("n", "<leader>/d", function()
	require("telescope.builtin").live_grep({ cwd = require("lazy.core.config").options.root or vim.fn.stdpath('data') })
end, { desc = "telescope live grep data" })

vim.notify(vim.fn.stdpath('data'))
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

-- Execute Lua: 用模式参数区分「行 / 选区」
local function lua_exec(mode)
	local code, name
	if mode == "v" then
		local m = vim.fn.visualmode()
		local a = vim.fn.getpos("'<")
		local b = vim.fn.getpos("'>")

		if m == "V" then
			code = table.concat(vim.api.nvim_buf_get_lines(0, a[2] - 1, b[2], false), "\n")
		else
			local end_row = b[2] - 1
			local end_line = vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, false)[1] or ""
			local end_col = b[3]
			if end_col >= vim.v.maxcol then
				end_col = #end_line
			elseif vim.o.selection == "exclusive" then
				end_col = end_col - 1
			end
			end_col = math.min(end_col, #end_line)
			code =
				table.concat(vim.api.nvim_buf_get_text(0, a[2] - 1, math.max(0, a[3] - 1), end_row, end_col, {}), "\n")
		end
		name = "@visual"
	else
		code = vim.api.nvim_get_current_line()
		name = "@cursor-line"
	end

	-- DEBUG: 先把捕获到的内容亮出来（确认无误后可删）
	if DEBUG then
		vim.notify(
			("[lua_exec] mode=%s vmode=%s bytes=%d\n%s"):format(
				mode,
				vim.fn.visualmode(),
				#(code or ""),
				(code or ""):sub(1, 300)
			),
			vim.log.levels.INFO
		)
	end

	if not code or code:match("^%s*$") then
		return
	end

	local chunk, err = load(code, name)
	if not chunk then
		local chunk2 = load("return " .. code, name)
		if chunk2 then
			chunk = chunk2
		else
			vim.notify(("%s\n--- code (%d bytes) ---\n%s"):format(err, #code, code), vim.log.levels.ERROR)
			return
		end
	end

	local ok, res = pcall(chunk)
	if not ok then
		vim.notify(tostring(res), vim.log.levels.ERROR)
	elseif res ~= nil then
		vim.notify(vim.inspect(res), vim.log.levels.INFO)
	end
end

_G.run_current_line = function()
	lua_exec("n")
end
_G.run_visual_selection = function()
	lua_exec("v")
end

map("n", "<LocalLeader>r", _G.run_current_line, { desc = "Execute current line as Nvim Lua" })
map("x", "<LocalLeader>r", _G.run_visual_selection, { desc = "Execute selection as Nvim Lua" })
