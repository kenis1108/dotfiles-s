return {
	{ "nvim-tree/nvim-tree.lua", enabled = false },
	{ "nvim-treesitter/nvim-treesitter", enabled = false },
	{
		"folke/snacks.nvim",
		opts = {
			dashboard = { enabled = false },
			explorer = { enabled = false },
		},
	},

	{
		"mikavilpas/yazi.nvim",
		version = "*",
		event = "VeryLazy",
		dependencies = {
			{ "nvim-lua/plenary.nvim", lazy = true },
		},
		keys = {
			{ mode = { "n", "v" }, "<leader>E", "<cmd>Yazi cwd<cr>", desc = "Open Yazi in working directory" },
			{ mode = { "n", "v" }, "<leader>e", "<cmd>Yazi<cr>", desc = "Open Yazi in current file directory" },
		},
		opts = {
			-- if you want to open yazi instead of netrw, see below for more info
			open_for_directories = false,
			keymaps = {
				show_help = "<f2>",
			},
		},
		-- 👇 if you use `open_for_directories=true`, this is recommended
		init = function()
			-- mark netrw as loaded so it's not loaded at all.
			--
			-- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
			vim.g.loaded_netrwPlugin = 1
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		opts = {
			defaults = {
				cache_picker = {
					num_pickers = -1, -- 保留最近几个 picker；-1 = 本会话全保留
					limit_entries = 2000, -- 每个 picker 最多缓存多少条结果
					ignore_empty_prompt = true, -- 空 prompt 就关的不进缓存
				},
			},
		},
	},

	{
		"folke/which-key.nvim",
		opts = {
			preset = "helix",
			keys = {
				scroll_down = "<c-n>", -- binding to scroll down inside the popup
				scroll_up = "<c-p>", -- binding to scroll up inside the popup
			},
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Keymaps (which-key)",
			},
		},
	},
}
