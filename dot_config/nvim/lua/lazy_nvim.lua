return {
  { "nvim-tree/nvim-tree.lua", enabled = false },
  { "nvim-treesitter/nvim-treesitter", enabled = false },
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
      local mr = require "mason-registry"
      mr:on("package:install:success", function()
        vim.defer_fn(function()
          -- trigger FileType event to possibly load this newly installed LSP server
          require("lazy.core.handler.event").trigger {
            event = "FileType",
            buf = vim.api.nvim_get_current_buf(),
          }
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
    "folke/snacks.nvim",
    enabled = vim.env.NVIM_APPNAME and vim.env.NVIM_APPNAME:find "lazyvim" ~= nil,
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
    enabled = vim.env.NVIM_APPNAME and vim.env.NVIM_APPNAME:find "nvchad" ~= nil,
    keys = {
      { "<leader>fb", "<cmd>Telescope builtin<cr>", desc = "Telescope find builtin" },
      -- 文件查找
      {
        "<leader>fc",
        function()
          require("telescope.builtin").find_files { cwd = vim.fn.stdpath "config" }
        end,
        desc = "Telescope find config",
      },
      {
        "<leader>fd",
        function()
          require("telescope.builtin").find_files {
            cwd = require("lazy.core.config").options.root or vim.fn.stdpath "data",
          }
        end,
        desc = "Telescope find data",
      },
      -- 内容搜索
      {
        "<leader>/c",
        function()
          require("telescope.builtin").live_grep { cwd = vim.fn.stdpath "config" }
        end,
        desc = "Telescope live grep config",
      },
      {
        "<leader>/d",
        function()
          require("telescope.builtin").live_grep {
            cwd = require("lazy.core.config").options.root or vim.fn.stdpath "data",
          }
        end,
        desc = "Telescope live grep data",
      },
    },
    opts = {
      defaults = {
        cache_picker = {
          num_pickers = -1, -- 保留最近几个 picker；-1 = 本会话全保留
          limit_entries = 2000, -- 每个 picker 最多缓存多少条结果
          ignore_empty_prompt = true, -- 空 prompt 就关的不进缓存
        },
      },
    },
    config = function(_, opts)
      require("telescope").setup(opts)
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
          require("which-key").show { global = false }
        end,
        desc = "Buffer Keymaps (which-key)",
      },
    },
  },
}