return {
	{ "nvim-tree/nvim-tree.lua", enabled = false },

	{ "nvim-treesitter/nvim-treesitter", enabled = false },

	{ "nvim-telescope/telescope.nvim", enabled = vim.env.NVIM_APPNAME and vim.env.NVIM_APPNAME:find("nvchad") ~= nil },

	{
		"folke/tokyonight.nvim",
    enabled = vim.env.NVIM_APPNAME and vim.env.NVIM_APPNAME:find("lazyvim") ~= nil,
		opts = {
			transparent = true,
			styles = {
				sidebars = "transparent",
				floats = "transparent",
			},
		},
	},

	{
		"lewis6991/gitsigns.nvim",
		event = "VeryLazy",
		opts = {
			signs = {
				delete = { text = "󰍵" },
				changedelete = { text = "󱕖" },
			},
		},
	},

	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = { lua = { "stylua" } },
		},
		keys = function()
			return {
				{
					mode = { "n", "x" },
					"<leader>=",
					function()
						require("conform").format({ lsp_fallback = true })
					end,
					desc = "general format file",
				},
			}
		end,
		-- 设置 formatexpr 以支持 Vim 的格式化命令
		init = function()
			-- If you want the formatexpr, here is the place to set it
			vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
		end,
	},

	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{
				"s",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash",
			},
			{
				"S",
				mode = { "n", "x", "o" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash Treesitter",
			},
			{
				"r",
				mode = "o",
				function()
					require("flash").remote()
				end,
				desc = "Remote Flash",
			},
			{
				"R",
				mode = { "o", "x" },
				function()
					require("flash").treesitter_search()
				end,
				desc = "Treesitter Search",
			},
			{
				"<c-s>",
				mode = { "c" },
				function()
					require("flash").toggle()
				end,
				desc = "Toggle Flash Search",
			},
		},
	},

	{
		"folke/snacks.nvim",
		lazy = false,
		opts = {
			dashboard = {
				enabled = false,
				preset = {
					header = [[
            .-. .-')     ('-.       .-') _          .-')             ('-. .-.          ('-. .-. 
            \  ( OO )  _(  OO)     ( OO ) )        ( OO ).          ( OO )  /         ( OO )  / 
            ,--. ,--. (,------.,--./ ,--,' ,-.-') (_)---\_)         ,--. ,--.     ,--.,--. ,--. 
            |  .'   /  |  .---'|   \ |  |\ |  |OO)/    _ |    .-')  |  | |  | .-')| ,||  | |  | 
            |      /,  |  |    |    \|  | )|  |  \\  :` `.  _(  OO) |   .|  |( OO |(_||   .|  | 
            |     ' _)(|  '--. |  .     |/ |  |(_/ '..`''.)(,------.|       || `-'|  ||       | 
            |  .   \   |  .--' |  |\    | ,|  |_.'.-._)   \ '------'|  .-.  |,--. |  ||  .-.  | 
            |  |\   \  |  `---.|  | \   |(_|  |   \       /         |  | |  ||  '-'  /|  | |  | 
            `--' '--'  `------'`--'  `--'  `--'    `-----'          `--' `--' `-----' `--' `--' 
          ]],
				},
			},
			explorer = { enabled = false },
			picker = { enable = true },
			scroll = { enable = true },
		},
		keys = {
			{
				"<leader>f",
				function()
					Snacks.picker()
				end,
				desc = "Open Snacks Picker",
			},
			{
				"<leader>fc",
				function()
					Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
				end,
				desc = "Find Config File",
			},
			{
				"<leader>fd",
				function()
					Snacks.picker.files({ cwd = require("lazy.core.config").options.root or vim.fn.stdpath("data") })
				end,
				desc = "Find Plugins Data",
			},
			{
				"<leader>/c",
				function()
					Snacks.picker.grep({ cwd = vim.fn.stdpath("config") })
				end,
				desc = "Grep Config File",
			},
			{
				"<leader>/d",
				function()
					Snacks.picker.grep({ cwd = require("lazy.core.config").options.root or vim.fn.stdpath("data") })
				end,
				desc = "Grep Plugins Data",
			},
		},
	},

	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason.nvim",
			{
				"mason-org/mason-lspconfig.nvim",
				lazy = false,
				opts = {},
			},
		},
	},
	{
		"mason-org/mason.nvim",
		lazy = false,
		opts_extend = { "ensure_installed" },
		opts = {
			ensure_installed = {
				"lua-language-server",
				"stylua",
			},
		},
		---@param opts MasonSettings | {ensure_installed: string[]}
		config = function(_, opts)
			require("mason").setup(opts)
			local mr = require("mason-registry")
			mr:on("package:install:success", function()
				vim.defer_fn(function()
					-- trigger FileType event to possibly load this newly installed LSP server
					require("lazy.core.handler.event").trigger({
						event = "FileType",
						buf = vim.api.nvim_get_current_buf(),
					})
				end, 100)
			end)

			-- 自动安装非 LSP 工具（Formatter、Linter、DAP 等）
			mr.refresh(function()
				for _, tool in ipairs(opts.ensure_installed) do
					local p = mr.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end)
		end,
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
		"folke/which-key.nvim",
		lazy = false,
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
