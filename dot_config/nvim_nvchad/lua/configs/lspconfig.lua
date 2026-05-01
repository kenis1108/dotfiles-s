require("nvchad.configs.lspconfig").defaults()

local servers = { "lua_ls", "vue_ls", "jsonls" }
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers
