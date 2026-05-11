return {
  -- color
  {
    "norcalli/nvim-colorizer.lua",
    event = "VeryLazy",
    config = function()
      require("colorizer").setup()
    end,
  },

  -- auto pairs
  {
    "echasnovski/mini.pairs",
    event = "InsertEnter", -- 进入插入模式时加载
    opts = {},
  },

  -- surround action
  {
    "echasnovski/mini.surround",
    event = "InsertEnter", -- 进入插入模式时加载
    opts = {},
  },

  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy", -- Or `LspAttach`
    priority = 1000, -- needs to be loaded in first
    opts = {},
  },

  {
    "folke/todo-comments.nvim",
    event = "BufReadPost", -- 文件读取后加载
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },

  -- 用于在 Neovim 中展示 LSP 诊断、快速修复、位置列表等信息的插件
  {
    "folke/trouble.nvim",
    event = "VeryLazy",
    opts = {
      modes = {
        lsp = {
          win = { position = "right" },
        },
      },
    },
    cmd = "Trouble",
  },

  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {},
    -- stylua: ignore
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },

  -- inlay hints
  {
    "MysticalDevil/inlay-hints.nvim",
    event = "LspAttach",
    dependencies = { "neovim/nvim-lspconfig" },
    config = function()
      require("inlay-hints").setup()
    end,
  },
}
