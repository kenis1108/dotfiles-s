return {
  {
    "stevearc/oil.nvim",
    enabled = false,
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    config = function()
      -- Declare a global function to retrieve the current directory
      function _G.get_oil_winbar()
        local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
        local dir = require("oil").get_current_dir(bufnr)
        if dir then
          return vim.fn.fnamemodify(dir, ":~")
        else
          -- If there is no current directory (e.g. over ssh), just show the buffer name
          return vim.api.nvim_buf_get_name(0)
        end
      end
      require("oil").setup({
        view_options = {
          show_hidden = true,
        },
        win_options = {
          winbar = "%!v:lua.get_oil_winbar()",
        },
      })
      vim.keymap.set("n", "<Leader>e", "<CMD>Oil<CR>", { desc = "[E]xplorer (oil)" })
    end,
  },
  {
    "echasnovski/mini.files",
    enabled = false,
    config = function()
      require("mini.files").setup()
      vim.keymap.set("n", "<Leader>e", MiniFiles.open, { desc = "[E]xplorer (mini.files)" })
    end,
  },
  {
    "mikavilpas/yazi.nvim",
    enabled = false,
    event = "VeryLazy",
    dependencies = {
      "folke/snacks.nvim",
    },
    keys = {
      -- 👇 in this section, choose your own keymappings!
      {
        "<leader>-",
        mode = { "n", "v" },
        "<cmd>Yazi<cr>",
        desc = "Open yazi at the current file",
      },
      {
        -- Open in the current working directory
        "<leader>cw",
        "<cmd>Yazi cwd<cr>",
        desc = "Open the file manager in nvim's working directory",
      },
      {
        "<c-up>",
        "<cmd>Yazi toggle<cr>",
        desc = "Resume the last yazi session",
      },
    },
    opts = {
      -- if you want to open yazi instead of netrw, see below for more info
      open_for_directories = false,
      keymaps = {
        show_help = "<f1>",
      },
    },
    -- 👇 if you use `open_for_directories=true`, this is recommended
    init = function()
      -- More details: https://github.com/mikavilpas/yazi.nvim/issues/802
      -- vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
  },
}
