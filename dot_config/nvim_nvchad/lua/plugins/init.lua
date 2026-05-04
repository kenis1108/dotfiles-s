return {
  -- {
  --   "stevearc/conform.nvim",
  --   -- event = 'BufWritePre', -- uncomment for format on save
  --   opts = require "configs.conform",
  -- },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- test new blink
  { import = "nvchad.blink.lazyspec" },

  {
    "mikavilpas/yazi.nvim",
    event = "VeryLazy",
    dependencies = {
      { "nvim-lua/plenary.nvim", lazy = true },
    },
    keys = {
      { mode = { "n", "v" }, "<leader>e", "<cmd>Yazi cwd<cr>", desc = "Open Yazi in nvim's working directory" },
    },
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
          require("which-key").show { global = false }
        end,
        desc = "Buffer Keymaps (which-key)",
      },
    },
  },
}
