﻿local function augroup(name)
	return vim.api.nvim_create_augroup("kenvim_" .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		(vim.hl or vim.highlight).on_yank()
	end,
})

local function nomap(mode, key)
	local ok, _ = pcall(vim.keymap.del, mode, key)
	if not ok then
		local msg = "nomap: " .. mode .. " " .. key .. " not found"
		vim.cmd("echomsg '" .. msg .. "'")
	end
end

vim.api.nvim_create_autocmd("User", {
	group = augroup("clean_distro_keymaps"),
	pattern = "VeryLazy",
	once = true,
	callback = function()
		if vim.env.NVIM_APPNAME then
			if vim.env.NVIM_APPNAME:find("nvchad") ~= nil then
				nomap("n", "<C-c>")
				-- telescope
				nomap("n", "<leader>fa")
				nomap("n", "<leader>fb")
				nomap("n", "<leader>ff")
				nomap("n", "<leader>fh")
				nomap("n", "<leader>fo")
				nomap("n", "<leader>fw")
				nomap("n", "<leader>fz")
				nomap("n", "<leader>ma")
				nomap("n", "<leader>gt")
				nomap("n", "<leader>cm")
				nomap("n", "<leader>pt")

				nomap({ "n", "x" }, "<leader>fm")
			end
			if vim.env.NVIM_APPNAME:find("lazyvim") ~= nil then
				nomap("n", "<leader>fe")
				nomap("n", "<leader>fE")

        nomap({ "n", "x" }, "<leader>cf")
			end
		end
	end,
})
