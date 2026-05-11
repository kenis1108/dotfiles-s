return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" }, -- 在保存文件前触发格式化
  cmd = { "ConformInfo" }, -- 注册 ConformInfo 命令，用于查看插件状态信息
  keys = {
    {
      "<leader>fm",
      function()
        require("conform").format({ async = true }, function(err)
          if not err then
            local mode = vim.api.nvim_get_mode().mode
            -- Leave visual mode after range format
            if vim.startswith(string.lower(mode), "v") then
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
            end
          end
        end)
      end,
      mode = "",
      desc = "[F]ormat buffer",
    },
  },
  -- This will provide type hinting with LuaLS
  ---@module "conform"
  ---@type conform.setupOpts
  opts = {
    -- Define your formatters
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "isort", "black" }, -- Python 先排序导入，再格式化
      -- 首选格式化工具是 prettierd，它是 prettier 的守护进程版本，启动更快，适合频繁格式化（如保存时自动格式化）。
      -- 备选工具是原生的 prettier，当前面的工具失败时会使用它。
      -- stop_after_first = true 只要有一个工具成功执行，就停止尝试后续工具
      javascript = { "prettierd", "prettier", stop_after_first = true },
    },
    -- Set default options
    default_format_opts = {
      lsp_format = "fallback", -- 使用 LSP 格式化作为后备方案
    },
    -- Set up format-on-save | 保存时自动格式化（超时时间 500ms）
    format_on_save = { timeout_ms = 500 },
    -- Customize formatters | 自定义格式化工具的参数
    --[[ formatters = {
      shfmt = {
        prepend_args = { "-i", "2" },
      },
    }, ]]
  },
  -- 设置 formatexpr 以支持 Vim 的格式化命令
  init = function()
    -- If you want the formatexpr, here is the place to set it
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
  end,
}
