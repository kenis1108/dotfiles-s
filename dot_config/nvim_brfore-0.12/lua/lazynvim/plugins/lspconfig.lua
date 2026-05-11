-- 有lsp了还需要treesitter吗?
-- lsp 提供智能编程功能（补全、跳转、诊断等）
-- treesitter 解析代码生成语法树，用于语法高亮、代码折叠等

return {
  -- mason.nvim 主要功能是安装和管理开发工具，比如 LSP 服务器、DAP 适配器、格式化工具（如 stylua）和 linters（如 luacheck）。
  -- 避免在不同系统上安装工具，比如省去手动scoop install stylua
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = {
      -- PATH = "skip", -- 禁止 Mason 自动修改 Neovim 的环境变量 PATH

      ui = {
        icons = {
          package_pending = " ",
          package_installed = " ",
          package_uninstalled = " ",
        },
      },

      max_concurrent_installers = 10,
    },
  },

  -- mason-lspconfig.nvim 是 mason.nvim 和 nvim-lspconfig 的桥梁，主要用于自动安装LSP和自动启动由 mason 安装的 LSP 服务器
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = { "lua_ls" },
    },
  },

  -- 配置需要自动安装的工具，mason-lspconfig不支持自动安装非 LSP 工具（如代码格式化器、静态分析工具等），所以使用这个插件来自动安装所有的开发工具并确保它们与 mason.nvim 同步更新
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        -- formatter
        "stylua",
      },

      start_delay = 3000,
    },
  },

  -- nvim-lspconfig 是 Nvim LSP 客户端的 LSP 服务器配置集合
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            hint = {
              enable = true, -- necessary
            },
          },
        },
      })
      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            schemaStore = {
              enable = true,
            },
            -- 其他配置
            format = { enabled = true },
            validate = true,
            completion = true,
            hover = true,
          },
        },
        filetypes = { "yaml", "yml" },
      })
    end,
  },
}
